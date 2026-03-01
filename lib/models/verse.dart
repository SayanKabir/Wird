import 'package:hive/hive.dart';

part 'verse.g.dart';

@HiveType(typeId: 31)
class Verse extends HiveObject {
  @HiveField(0)
  final int surahId;

  @HiveField(1)
  final int verseNumber;

  @HiveField(2)
  final String verseKey; // "1:1"

  @HiveField(3)
  final String textUthmani;

  @HiveField(4)
  final int page;

  @HiveField(5)
  final int juz;

  @HiveField(6)
  final String? translationText;

  @HiveField(7)
  final String? translationName; // e.g. "Saheeh International"

  @HiveField(8)
  final String? transliterationText; // e.g. "Bismi Allahi arrahmani arraheem"

  Verse({
    required this.surahId,
    required this.verseNumber,
    required this.verseKey,
    required this.textUthmani,
    required this.page,
    required this.juz,
    this.translationText,
    this.translationName,
    this.transliterationText,
  });

  factory Verse.fromJson(Map<String, dynamic> json, {int? overrideSurahId}) {
    final verseKey = json['verse_key'] as String? ?? '';
    final parts = verseKey.split(':');
    final surahId = overrideSurahId ?? (parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0);

    // Extract translation from the translations array
    String? translationText;
    String? translationName;
    final translations = json['translations'] as List<dynamic>?;
    if (translations != null && translations.isNotEmpty) {
      final first = translations[0] as Map<String, dynamic>;
      // The API returns HTML with footnotes like <sup foot_note=...>1</sup>
      // First remove <sup>…</sup> elements entirely, then strip remaining tags
      translationText = (first['text'] as String? ?? '')
          .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      translationName = first['resource_name'] as String?;
    }

    // Extract transliteration (injected by QuranApiService)
    final transliterationText = json['transliteration_text'] as String?;

    return Verse(
      surahId: surahId,
      verseNumber: json['verse_number'] as int? ?? 0,
      verseKey: verseKey,
      textUthmani: json['text_uthmani'] as String? ?? '',
      page: json['page_number'] as int? ?? 0,
      juz: json['juz_number'] as int? ?? 0,
      translationText: translationText,
      translationName: translationName,
      transliterationText: transliterationText,
    );
  }
}
