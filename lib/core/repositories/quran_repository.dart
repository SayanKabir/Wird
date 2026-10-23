import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/quran_bookmark.dart';
import '../../models/settings.dart';
import '../../models/surah.dart';
import '../../models/verse.dart';
import '../quran/quran_disk_cache.dart';
import '../quran/quran_meta.dart';
import '../quran/quran_translations.dart';
import '../quran/transliterator.dart';
import '../services/quran_api_service.dart';

/// Everything the reader needs for one surah.
class SurahContent {
  final List<Verse> verses;

  /// False when a translation was requested but couldn't be fetched (offline
  /// and never downloaded). The Arabic is still shown.
  final bool translationAvailable;

  const SurahContent({required this.verses, this.translationAvailable = true});
}

/// Where a local search match was found.
enum SearchMatchSource { translation, transliteration, arabic }

class LocalSearchHit {
  final int surah;
  final int verse;
  final String snippet;
  final SearchMatchSource source;

  const LocalSearchHit({required this.surah, required this.verse, required this.snippet, required this.source});

  String get verseKey => '$surah:$verse';
}

/// Quran data, offline-first.
///
/// * Surah list and English transliteration ship with the app (assets).
/// * Arabic text is downloaded per surah the first time it's opened, or for
///   the whole Quran on request, and kept on disk for good.
/// * A translation is fetched for the open surah right away, and the whole
///   translation is then downloaded in the background so every other surah
///   works offline too.
class QuranRepository {
  static const String _bookmarkBoxName = 'quran_bookmarks';

  final QuranApiService _api;
  final QuranDiskCache _cache;

  late Box<QuranBookmark> _bookmarkBox;
  List<Surah> _surahs = const [];
  List<String>? _transliterationEn;
  final Map<TransliterationScript, List<String?>> _converted = {};

  // Whole-Quran lists stay in memory once loaded: ~1–2 MB each, and the
  // reader keeps asking for slices of the same one.
  final Map<String, List<String>> _fullCache = {};

  final Map<String, Future<void>> _inFlight = {};

  /// Keys ("translation_20", "arabic_indopak") currently downloading in full.
  final ValueNotifier<Set<String>> activeDownloads = ValueNotifier(const {});

  QuranRepository({QuranApiService? apiService, QuranDiskCache? cache})
      : _api = apiService ?? QuranApiService(),
        _cache = cache ?? QuranDiskCache();

  Future<void> init() async {
    _bookmarkBox = await Hive.openBox<QuranBookmark>(_bookmarkBoxName);
    _surahs = await _loadBundledSurahs();
    unawaited(_removeLegacyCaches());
  }

  // ─────────────────── Surahs ───────────────────

  List<Surah> get surahs => _surahs;

  Future<List<Surah>> getSurahs() async {
    if (_surahs.isEmpty) _surahs = await _loadBundledSurahs();
    return _surahs;
  }

  Surah? surahById(int id) => id >= 1 && id <= _surahs.length ? _surahs[id - 1] : null;

  Future<List<Surah>> _loadBundledSurahs() async {
    final raw = await rootBundle.loadString('assets/quran/chapters.json');
    final chapters = (jsonDecode(raw) as Map<String, dynamic>)['chapters'] as List<dynamic>;
    return chapters.map((c) => Surah.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ─────────────────── Verses ───────────────────

  static String _arabicKey(QuranScript script, [int? surah]) =>
      'arabic_${script.cacheKey}_${surah ?? 'all'}';
  static String _translationKey(int id, [int? surah]) => 'translation_${id}_${surah ?? 'all'}';

  /// Loads a surah from disk, downloading only what's missing.
  ///
  /// Throws only if the Arabic isn't on disk and can't be downloaded.
  Future<SurahContent> getSurahContent(
    int surahId, {
    required QuranScript script,
    int? translationId,
    TransliterationScript? transliteration,
  }) async {
    final arabicFuture = _arabicFor(surahId, script);
    final translationFuture = translationId == null
        ? Future<List<String>?>.value(null)
        : _translationFor(surahId, translationId).then<List<String>?>((v) => v, onError: (_) => null);
    final translitFuture = transliteration == null
        ? Future<List<String>?>.value(null)
        : transliterationFor(surahId, transliteration);

    final arabic = await arabicFuture;
    final translation = await translationFuture;
    final translit = await translitFuture;
    final translationName = translationId != null ? QuranTranslations.byId(translationId).name : null;

    final verses = <Verse>[
      for (var i = 0; i < arabic.length; i++)
        Verse(
          surahId: surahId,
          verseNumber: i + 1,
          verseKey: '$surahId:${i + 1}',
          textUthmani: _displayableArabic(arabic[i]),
          page: 0,
          juz: QuranMeta.juzOf(surahId, i + 1),
          translationText: translation != null && i < translation.length ? translation[i] : null,
          translationName: translationName,
          transliterationText: translit != null && i < translit.length ? translit[i] : null,
        ),
    ];

    if (translationId != null) {
      // Pull the whole translation down in the background so the rest of the
      // Quran is readable offline too.
      unawaited(downloadTranslation(translationId).catchError((_) {}));
    }

    return SurahContent(
      verses: verses,
      translationAvailable: translationId == null || translation != null,
    );
  }

  /// Drops stray byte-order marks and collapses runs of spaces. The Indo-Pak
  /// text's waqf marks live in the Private Use Area and are kept: the
  /// bundled IndoPak Nastaleeq font draws them.
  static String _displayableArabic(String text) => text
      .replaceAll('\uFEFF', '')
      .replaceAll(RegExp(r'[ \u2002\u2003]{2,}'), ' ')
      .trim();

  Future<List<String>> _arabicFor(int surahId, QuranScript script) async {
    final full = await _loadFull(_arabicKey(script));
    if (full != null) return _slice(full, surahId);

    final key = _arabicKey(script, surahId);
    final cached = await _cache.read(key);
    if (cached != null && cached.length == QuranMeta.verseCounts[surahId - 1]) return cached;

    final fetched = await _api.fetchChapterArabic(surahId, script);
    await _cache.write(key, fetched);
    return fetched;
  }

  Future<List<String>> _translationFor(int surahId, int translationId) async {
    final full = await _loadFull(_translationKey(translationId));
    if (full != null) return _slice(full, surahId);

    final key = _translationKey(translationId, surahId);
    final cached = await _cache.read(key);
    if (cached != null) return cached;

    final fetched = await _api.fetchChapterTranslation(surahId, translationId);
    await _cache.write(key, fetched);
    return fetched;
  }

  List<String> _slice(List<String> full, int surahId) {
    final (start, end) = QuranMeta.surahRange(surahId);
    return full.sublist(start, end);
  }

  Future<List<String>?> _loadFull(String key) async {
    final mem = _fullCache[key];
    if (mem != null) return mem;
    final disk = await _cache.read(key);
    if (disk == null || disk.length != QuranMeta.totalVerses) return null;
    // Keep at most one Arabic and one translation resident.
    _fullCache.removeWhere((k, _) => k.split('_').first == key.split('_').first);
    return _fullCache[key] = disk;
  }

  // ─────────────────── Transliteration ───────────────────

  Future<List<String>> _englishTransliteration() async {
    if (_transliterationEn != null) return _transliterationEn!;
    final raw = await rootBundle.loadString('assets/quran/transliteration_en.txt');
    return _transliterationEn = const LineSplitter().convert(raw);
  }

  Future<List<String>> transliterationFor(int surahId, TransliterationScript script) async {
    final en = await _englishTransliteration();
    final (start, end) = QuranMeta.surahRange(surahId);
    if (script == TransliterationScript.latin) return en.sublist(start, end);
    final converted = _converted.putIfAbsent(script, () => List<String?>.filled(en.length, null));
    return [
      for (var i = start; i < end; i++) converted[i] ??= Transliterator.convert(en[i], script),
    ];
  }

  // ─────────────────── Downloads ───────────────────

  Future<bool> isTranslationDownloaded(int id) => _cache.has(_translationKey(id));

  Future<bool> isQuranDownloaded(QuranScript script) => _cache.has(_arabicKey(script));

  /// Surahs whose Arabic is on disk for [script] (all 114 if fully downloaded).
  Future<Set<int>> downloadedSurahs(QuranScript script) async {
    if (await isQuranDownloaded(script)) return {for (var i = 1; i <= 114; i++) i};
    final prefix = 'arabic_${script.cacheKey}_';
    final keys = await _cache.keys(prefix);
    return keys.map((k) => int.tryParse(k.substring(prefix.length))).whereType<int>().toSet();
  }

  /// Downloads a whole translation (one ~1 MB request) and saves it.
  Future<void> downloadTranslation(int id) {
    final key = _translationKey(id);
    return _download(key, () async {
      final all = await _api.fetchAllTranslation(id);
      if (all.length != QuranMeta.totalVerses) throw Exception('Incomplete translation');
      await _cache.write(key, all);
      await _dropPerSurah('translation_${id}_');
    });
  }

  /// Downloads the Arabic text of the whole Quran in one script.
  Future<void> downloadQuran(QuranScript script) {
    final key = _arabicKey(script);
    return _download(key, () async {
      final all = await _api.fetchAllArabic(script);
      if (all.length != QuranMeta.totalVerses) throw Exception('Incomplete download');
      await _cache.write(key, all);
      await _dropPerSurah('arabic_${script.cacheKey}_');
    });
  }

  Future<void> _download(String key, Future<void> Function() run) {
    if (_inFlight.containsKey(key)) return _inFlight[key]!;
    return _inFlight[key] = () async {
      if (await _cache.has(key)) return;
      final label = key.substring(0, key.lastIndexOf('_'));
      activeDownloads.value = {...activeDownloads.value, label};
      try {
        await run();
      } finally {
        activeDownloads.value = {...activeDownloads.value}..remove(label);
        _inFlight.remove(key);
      }
    }();
  }

  /// Per-surah files are redundant once the whole-Quran file exists.
  Future<void> _dropPerSurah(String prefix) async {
    for (final k in await _cache.keys(prefix)) {
      if (!k.endsWith('_all')) await _cache.delete(k);
    }
  }

  Future<int> downloadedBytes() => _cache.sizeInBytes();

  Future<void> clearDownloads() async {
    _fullCache.clear();
    await _cache.clear();
  }

  // ─────────────────── Search ───────────────────

  Future<QuranSearchPage> searchOnline(String query, {int page = 1}) => _api.search(query, page: page);

  /// Searches whatever is available offline: the bundled transliteration,
  /// the downloaded translation, and any downloaded Arabic.
  Future<List<LocalSearchHit>> searchLocal(
    String query, {
    int? translationId,
    QuranScript? script,
    int limit = 60,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final hits = <LocalSearchHit>[];
    final seen = <int>{};

    void add(int index, String text, SearchMatchSource source) {
      if (hits.length >= limit || !seen.add(index)) return;
      final (s, v) = QuranMeta.fromGlobalIndex(index);
      hits.add(LocalSearchHit(surah: s, verse: v, snippet: text, source: source));
    }

    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(q);

    if (isArabic) {
      final needle = _normalizeArabic(q);
      if (script != null) {
        final full = await _loadFull(_arabicKey(script));
        if (full != null) {
          for (var i = 0; i < full.length; i++) {
            if (_normalizeArabic(full[i]).contains(needle)) add(i, full[i], SearchMatchSource.arabic);
          }
        } else {
          for (final s in (await downloadedSurahs(script)).toList()..sort()) {
            final verses = await _cache.read(_arabicKey(script, s));
            if (verses == null) continue;
            final (start, _) = QuranMeta.surahRange(s);
            for (var i = 0; i < verses.length; i++) {
              if (_normalizeArabic(verses[i]).contains(needle)) add(start + i, verses[i], SearchMatchSource.arabic);
            }
          }
        }
      }
      return hits;
    }

    if (translationId != null) {
      final full = await _loadFull(_translationKey(translationId));
      if (full != null) {
        final words = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        for (var i = 0; i < full.length; i++) {
          final text = full[i].toLowerCase();
          if (words.every(text.contains)) add(i, full[i], SearchMatchSource.translation);
        }
      }
    }

    final en = await _englishTransliteration();
    final needle = _normalizeLatin(q);
    if (needle.length >= 3) {
      for (var i = 0; i < en.length; i++) {
        if (_normalizeLatin(en[i]).contains(needle)) add(i, en[i], SearchMatchSource.transliteration);
      }
    }
    return hits;
  }

  /// Folds spelling variants so "rahman", "Rahmaan" and "ar-rahmaan" match.
  static String _normalizeLatin(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z]"), '')
      .replaceAll('ee', 'i')
      .replaceAll('oo', 'u')
      .replaceAll('e', 'i')
      .replaceAll('o', 'u')
      .replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);

  /// Strips harakat and folds letter variants so plain typed Arabic matches.
  static String _normalizeArabic(String s) => s
      .replaceAll(RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ‏]'), '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ۡ', '')
      .replaceAll('ة', 'ه')
      .replaceAll('ڪ', 'ك')
      .replaceAll(RegExp(r'\s+'), ' ');

  // ─────────────────── Bookmarks ───────────────────

  /// Get all user bookmarks (excluding last-read)
  List<QuranBookmark> getBookmarks() {
    return _bookmarkBox.values
        .where((b) => !b.isLastRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Save a bookmark
  Future<void> saveBookmark(QuranBookmark bookmark) async {
    await _bookmarkBox.put(bookmark.id, bookmark);
  }

  /// Delete a bookmark
  Future<void> deleteBookmark(String id) async {
    await _bookmarkBox.delete(id);
  }

  // ─────────────────── Last Read ───────────────────

  /// Get last read position
  QuranBookmark? getLastRead() {
    try {
      return _bookmarkBox.values.firstWhere((b) => b.isLastRead);
    } catch (_) {
      return null;
    }
  }

  /// Save last read position (replaces previous)
  Future<void> saveLastRead({
    required int surahId,
    required int verseNumber,
    String? surahName,
  }) async {
    // Remove previous last-read entries
    final existingKeys = _bookmarkBox.keys.where((key) {
      final bm = _bookmarkBox.get(key);
      return bm != null && bm.isLastRead;
    }).toList();
    for (final key in existingKeys) {
      await _bookmarkBox.delete(key);
    }

    // Save new last-read
    final bookmark = QuranBookmark(
      id: 'last_read',
      surahId: surahId,
      verseNumber: verseNumber,
      surahName: surahName,
      createdAt: DateTime.now(),
      isLastRead: true,
    );
    await _bookmarkBox.put('last_read', bookmark);
  }

  // ─────────────────── Housekeeping ───────────────────

  /// Earlier versions cached verses in one Hive box per surah/translation/
  /// script combination. Those are superseded by [QuranDiskCache].
  Future<void> _removeLegacyCaches() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.startsWith('quran_verses_') || name.startsWith('quran_surahs.')) {
          await f.delete();
        }
      }
    } catch (e) {
      debugPrint('[QuranRepository] legacy cache cleanup skipped: $e');
    }
  }

  void dispose() {
    _api.dispose();
    activeDownloads.dispose();
  }
}
