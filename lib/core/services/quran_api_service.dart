import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/settings.dart';
import '../quran/quran_translations.dart';

/// One verse match from Quran.com's full-text search.
class QuranSearchHit {
  final String verseKey;
  final String arabic;

  /// Matched translation text with `<em>` highlights stripped.
  final String? translation;

  const QuranSearchHit({required this.verseKey, required this.arabic, this.translation});

  int get surah => int.parse(verseKey.split(':')[0]);
  int get verse => int.parse(verseKey.split(':')[1]);
}

class QuranSearchPage {
  final int totalResults;
  final int totalPages;
  final List<QuranSearchHit> results;

  const QuranSearchPage({required this.totalResults, required this.totalPages, required this.results});
}

/// Thin client for the Quran.com API (v4).
///
/// Every call retries with backoff, so a flaky connection usually still gets
/// through; callers persist what comes back so each piece is fetched once.
class QuranApiService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const String _cdnUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions';

  final http.Client _client;

  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Arabic text of every ayah in a surah, in verse order.
  Future<List<String>> fetchChapterArabic(int surahId, QuranScript script) async {
    final data = await _getJson('/quran/verses/${script.cacheKey}?chapter_number=$surahId');
    return _arabicList(data, script);
  }

  /// Arabic text of the whole Quran (6236 ayahs), in Mushaf order.
  Future<List<String>> fetchAllArabic(QuranScript script) async {
    final data = await _getJson('/quran/verses/${script.cacheKey}', timeout: const Duration(seconds: 90));
    return _arabicList(data, script);
  }

  /// One translation for a surah, in verse order, with footnote markup removed.
  Future<List<String>> fetchChapterTranslation(int surahId, int translationId) async {
    final edition = QuranTranslations.byId(translationId).cdnEdition;
    if (edition != null) {
      final data = await _getJson('/$edition/$surahId.min.json', baseUrl: _cdnUrl);
      return _cdnList(data['chapter']);
    }
    final data = await _getJson('/quran/translations/$translationId?chapter_number=$surahId');
    return _translationList(data);
  }

  /// One translation for the whole Quran (6236 ayahs), in Mushaf order.
  Future<List<String>> fetchAllTranslation(int translationId) async {
    final edition = QuranTranslations.byId(translationId).cdnEdition;
    if (edition != null) {
      final data = await _getJson('/$edition.min.json', baseUrl: _cdnUrl, timeout: const Duration(seconds: 90));
      return _cdnList(data['quran']);
    }
    final data = await _getJson('/quran/translations/$translationId', timeout: const Duration(seconds: 90));
    return _translationList(data);
  }

  /// Full-text search across the Arabic and translations.
  Future<QuranSearchPage> search(String query, {int page = 1, int size = 20}) async {
    final q = Uri.encodeQueryComponent(query);
    final data = await _getJson('/search?q=$q&size=$size&page=$page', retries: 1);
    final search = data['search'] as Map<String, dynamic>? ?? const {};
    final results = (search['results'] as List<dynamic>? ?? const []).map((r) {
      final map = r as Map<String, dynamic>;
      final translations = map['translations'] as List<dynamic>? ?? const [];
      return QuranSearchHit(
        verseKey: map['verse_key'] as String,
        arabic: (map['text'] as String? ?? '').trim(),
        translation: translations.isEmpty
            ? null
            : cleanTranslation((translations.first as Map<String, dynamic>)['text'] as String? ?? ''),
      );
    }).toList();
    return QuranSearchPage(
      totalResults: search['total_results'] as int? ?? results.length,
      totalPages: search['total_pages'] as int? ?? 1,
      results: results,
    );
  }

  /// Strips the HTML Quran.com puts in translations: footnote markers
  /// (`<sup foot_note=…>1</sup>`), search highlights and any other tags.
  static String cleanTranslation(String html) {
    return html
        .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _arabicList(Map<String, dynamic> data, QuranScript script) {
    final verses = data['verses'] as List<dynamic>? ?? const [];
    if (verses.isEmpty) throw Exception('No verses returned');
    return verses.map((v) => ((v as Map<String, dynamic>)[script.apiFieldName] as String? ?? '').trim()).toList();
  }

  /// fawazahmed0 editions: `[{chapter, verse, text}, …]` in Mushaf order.
  List<String> _cdnList(Object? list) {
    final verses = list as List<dynamic>? ?? const [];
    if (verses.isEmpty) throw Exception('No translation returned');
    return verses.map((v) => ((v as Map<String, dynamic>)['text'] as String? ?? '').trim()).toList();
  }

  List<String> _translationList(Map<String, dynamic> data) {
    final list = data['translations'] as List<dynamic>? ?? const [];
    if (list.isEmpty) throw Exception('No translation returned');
    return list.map((t) => cleanTranslation((t as Map<String, dynamic>)['text'] as String? ?? '')).toList();
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    String baseUrl = _baseUrl,
    Duration timeout = const Duration(seconds: 20),
    int retries = 3,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < retries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 600 * attempt * attempt));
      }
      try {
        final response = await _client.get(Uri.parse('$baseUrl$path')).timeout(timeout);
        if (response.statusCode == 200) {
          return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }
        lastError = Exception('HTTP ${response.statusCode}');
        // Client errors won't fix themselves on retry.
        if (response.statusCode >= 400 && response.statusCode < 500) break;
      } catch (e) {
        lastError = e;
      }
    }
    debugPrint('[QuranApiService] $path failed: $lastError');
    throw lastError ?? Exception('Request failed');
  }

  void dispose() {
    _client.close();
  }
}
