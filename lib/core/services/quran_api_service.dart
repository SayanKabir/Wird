import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/surah.dart';
import '../../models/verse.dart';

/// Service for interacting with the Quran.com API (v4)
class QuranApiService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  // Saheeh International (default translation)
  static const int defaultTranslationId = 20;
  // English transliteration resource
  static const int transliterationId = 57;

  final http.Client _client;

  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all 114 surahs
  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/chapters?language=en'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final chapters = data['chapters'] as List<dynamic>;

      return chapters
          .map((ch) => Surah.fromJson(ch as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[QuranApiService] getAllSurahs error: $e');
      rethrow;
    }
  }

  /// Fetch ALL verses for a surah with translations + transliteration merged in.
  ///
  /// The v4 API requires separate calls:
  /// 1. `/verses/by_chapter/{id}` for Arabic text
  /// 2. `/quran/translations/{translationId}?chapter_number={id}` for English
  /// 3. `/quran/translations/{transliterationId}?chapter_number={id}` for transliteration
  ///
  /// We merge them by verse order (all return in verse_number order).
  Future<List<Verse>> getAllVersesBySurah(
    int surahId, {
    int translationId = defaultTranslationId,
  }) async {
    try {
      // Start all three fetches in parallel
      final versesFuture = _fetchAllVersePages(surahId);
      final translationsFuture = _fetchTranslationData(surahId, translationId);
      final translitFuture = _fetchTranslationData(surahId, transliterationId);

      final verseJsonList = await versesFuture;
      final translationsList = await translationsFuture;
      final translitList = await translitFuture;

      // Get translation resource name
      String? translationName;
      if (translationsList.isNotEmpty) {
        translationName = translationsList[0]['resource_name'] as String?;
      }

      // Merge: pair each verse with its translation + transliteration by index
      final verses = <Verse>[];
      for (var i = 0; i < verseJsonList.length; i++) {
        final vJson = verseJsonList[i];

        // Add translation data
        if (i < translationsList.length) {
          final tData = translationsList[i];
          vJson['translations'] = [
            {
              'text': tData['text'] ?? '',
              'resource_name': translationName ?? 'Translation',
            }
          ];
        }

        // Add transliteration data
        if (i < translitList.length) {
          final litData = translitList[i];
          vJson['transliteration_text'] = litData['text'] ?? '';
        }

        verses.add(Verse.fromJson(vJson, overrideSurahId: surahId));
      }

      return verses;
    } catch (e) {
      debugPrint('[QuranApiService] getAllVersesBySurah($surahId) error: $e');
      rethrow;
    }
  }

  /// Fetch all verse pages (handles pagination)
  Future<List<Map<String, dynamic>>> _fetchAllVersePages(int surahId) async {
    final allVerses = <Map<String, dynamic>>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_chapter/$surahId'
        '?language=en'
        '&fields=text_uthmani,verse_key,verse_number,page_number,juz_number'
        '&page=$page'
        '&per_page=50',
      );

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load verses page $page: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>?;

      allVerses.addAll(
        verses.map((v) => v as Map<String, dynamic>),
      );

      final totalPages = pagination?['total_pages'] as int? ?? 1;
      hasMore = page < totalPages;
      page++;
    }

    return allVerses;
  }

  /// Fetch translation/transliteration data for a chapter
  Future<List<Map<String, dynamic>>> _fetchTranslationData(
    int surahId,
    int resourceId,
  ) async {
    try {
      // Get resource name
      String? resourceName;
      try {
        final infoUri = Uri.parse('$_baseUrl/resources/translations/$resourceId');
        final infoResponse = await _client.get(infoUri);
        if (infoResponse.statusCode == 200) {
          final infoData = json.decode(infoResponse.body) as Map<String, dynamic>;
          final translation = infoData['translation'] as Map<String, dynamic>?;
          resourceName = translation?['name'] as String? ??
              translation?['author_name'] as String?;
        }
      } catch (_) {
        // Non-critical
      }

      final uri = Uri.parse(
        '$_baseUrl/quran/translations/$resourceId'
        '?chapter_number=$surahId',
      );

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        debugPrint('[QuranApiService] resource $resourceId fetch failed: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final translations = data['translations'] as List<dynamic>? ?? [];

      return translations.map((t) {
        final map = t as Map<String, dynamic>;
        if (resourceName != null) {
          map['resource_name'] = resourceName;
        }
        return map;
      }).toList();
    } catch (e) {
      debugPrint('[QuranApiService] _fetchTranslationData($resourceId) error: $e');
      return []; // Non-fatal: return empty so verses still load
    }
  }

  void dispose() {
    _client.close();
  }
}
