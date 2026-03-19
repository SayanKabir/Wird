import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../models/quran_bookmark.dart';
import '../services/quran_api_service.dart';

/// Repository for Quran data, combining API + Hive cache for offline-first
class QuranRepository {
  static const String _surahBoxName = 'quran_surahs';
  static const String _verseBoxPrefix = 'quran_verses_'; // per surah
  static const String _bookmarkBoxName = 'quran_bookmarks';

  final QuranApiService _apiService;

  late Box<Surah> _surahBox;
  late Box<QuranBookmark> _bookmarkBox;

  QuranRepository({QuranApiService? apiService})
      : _apiService = apiService ?? QuranApiService();

  Future<void> init() async {
    _surahBox = await Hive.openBox<Surah>(_surahBoxName);
    _bookmarkBox = await Hive.openBox<QuranBookmark>(_bookmarkBoxName);
  }

  // ─────────────────── Surahs ───────────────────

  /// Get all surahs (cache-first, API fallback)
  Future<List<Surah>> getSurahs() async {
    // Return cache if available
    if (_surahBox.isNotEmpty) {
      return _surahBox.values.toList();
    }

    // Fetch from API and cache
    try {
      final surahs = await _apiService.getAllSurahs();
      await _cacheSurahs(surahs);
      return surahs;
    } catch (e) {
      debugPrint('[QuranRepository] getSurahs error: $e');
      // Return whatever we have cached, even if empty
      return _surahBox.values.toList();
    }
  }

  /// Force refresh surahs from API
  Future<List<Surah>> refreshSurahs() async {
    final surahs = await _apiService.getAllSurahs();
    await _cacheSurahs(surahs);
    return surahs;
  }

  Future<void> _cacheSurahs(List<Surah> surahs) async {
    await _surahBox.clear();
    for (final surah in surahs) {
      await _surahBox.put(surah.id, surah);
    }
  }

  // ─────────────────── Verses ───────────────────

  /// Get verses for a surah (cache-first, API fallback)
  /// Re-fetches if cached data lacks translations.
  Future<List<Verse>> getVerses(int surahId, {String? translationName, String scriptFieldName = 'text_uthmani'}) async {
    final translationId = _getTranslationId(translationName);
    final boxName = '${_verseBoxPrefix}${surahId}_${translationId}_$scriptFieldName';
    final box = await Hive.openBox<Verse>(boxName);

    // Return cache if available AND has translations
    if (box.isNotEmpty) {
      final cached = box.values.toList()
        ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

      // Check if translations AND transliteration are present (stale cache detection)
      final hasTranslations = cached.any(
        (v) => v.translationText != null && v.translationText!.isNotEmpty,
      );
      final hasTransliteration = cached.any(
        (v) => v.transliterationText != null && v.transliterationText!.isNotEmpty,
      );

      // Check if the cached translation matches the requested one
      final hasMatchingTranslation = cached.any(
        (v) => v.translationName != null &&
               v.translationName!.toLowerCase().contains(
                   translationName?.split(' ').first.toLowerCase() ?? 'saheeh'
               ),
      );

      if (hasTranslations && hasTransliteration && hasMatchingTranslation) {
        return cached;
      }
      // Otherwise fall through to re-fetch
    }

    // Fetch from API and cache
    try {
      final verses = await _apiService.getAllVersesBySurah(
        surahId,
        translationId: translationId,
        scriptFieldName: scriptFieldName,
      );
      await _cacheVerses(box, verses);
      return verses;
    } catch (e) {
      debugPrint('[QuranRepository] getVerses($surahId) error: $e');
      return box.values.toList()
        ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    }
  }

  /// Force refresh verses from API
  Future<List<Verse>> refreshVerses(int surahId, {String? translationName, String scriptFieldName = 'text_uthmani'}) async {
    final translationId = _getTranslationId(translationName);
    final boxName = '${_verseBoxPrefix}${surahId}_${translationId}_$scriptFieldName';
    final box = await Hive.openBox<Verse>(boxName);
    final verses = await _apiService.getAllVersesBySurah(
      surahId,
      translationId: translationId,
      scriptFieldName: scriptFieldName,
    );
    await _cacheVerses(box, verses);
    return verses;
  }

  int _getTranslationId(String? name) {
    if (name == null) return QuranApiService.defaultTranslationId;
    switch (name) {
      case 'Mustafa Khattab':
        return 85; // Fallback to Haleem since Khattab (131) was removed from v4 API
      case 'Saheeh Intl':
        return 20;
      case 'Yusuf Ali':
        return 22;
      default:
        return QuranApiService.defaultTranslationId;
    }
  }

  Future<void> _cacheVerses(Box<Verse> box, List<Verse> verses) async {
    await box.clear();
    for (final verse in verses) {
      await box.put(verse.verseKey, verse);
    }
  }

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

  /// Check if surah data is cached
  Future<bool> isSurahCached(int surahId) async {
    final boxName = '$_verseBoxPrefix$surahId';
    final box = await Hive.openBox<Verse>(boxName);
    return box.isNotEmpty;
  }

  void dispose() {
    _apiService.dispose();
  }
}
