import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/features/quran/sharing/verse_share.dart';
import 'package:wird2/models/surah.dart';
import 'package:wird2/models/verse.dart';

Surah _surah(int id, String name) => Surah(
      id: id,
      nameArabic: '',
      nameTranslation: '',
      nameTransliteration: name,
      versesCount: 286,
      revelationPlace: 'madinah',
      revelationOrder: 87,
      pages: const [],
    );

Verse _verse(int n) => Verse(
      surahId: 2,
      verseNumber: n,
      verseKey: '2:$n',
      textUthmani: 'arabic $n',
      page: 0,
      juz: 3,
      translationText: 'meaning $n',
      translationName: 'Saheeh International',
    );

void main() {
  final baqarah = _surah(2, 'Al-Baqarah');

  group('VerseShare', () {
    test('formats contiguous and gapped references', () {
      expect(VerseShare(surah: baqarah, verses: [_verse(255)]).reference, '2:255');
      expect(VerseShare(surah: baqarah, verses: [_verse(257), _verse(255), _verse(256)]).reference, '2:255–257');
      expect(VerseShare(surah: baqarah, verses: [_verse(255), _verse(256), _verse(260)]).reference, '2:255–256, 260');
    });

    test('links to quran.com', () {
      expect(VerseShare(surah: baqarah, verses: [_verse(255)]).link.toString(), 'https://quran.com/2/255');
      expect(VerseShare(surah: baqarah, verses: [_verse(255), _verse(257)]).link.toString(), 'https://quran.com/2/255-257');
    });

    test('text ends with reference and link', () {
      final text = VerseShare(surah: baqarah, verses: [_verse(255)]).toText();
      expect(text, contains('meaning 255'));
      expect(text, endsWith('— Quran, Al-Baqarah 2:255 · Saheeh International\nhttps://quran.com/2/255'));
    });
  });

  group('verseRefFromLink', () {
    void expectRef(String url, int s, int v, [int? to]) {
      final ref = verseRefFromLink(Uri.parse(url), surahs: [baqarah]);
      expect(ref?.surah, s, reason: url);
      expect(ref?.verse, v, reason: url);
      expect(ref?.toVerse, to, reason: url);
    }

    test('parses quran.com formats', () {
      expectRef('https://quran.com/2/255', 2, 255);
      expectRef('https://quran.com/2/255-257', 2, 255, 257);
      expectRef('https://quran.com/2:255', 2, 255);
      expectRef('https://www.quran.com/en/2/255', 2, 255);
      expectRef('https://quran.com/2?startingVerse=10', 2, 10);
      expectRef('https://quran.com/al-baqarah/255-257', 2, 255, 257);
      expectRef('https://quran.com/ayatul-kursi', 2, 255);
      expectRef('https://quran.com/36', 36, 1);
    });

    test('rejects other links', () {
      expect(verseRefFromLink(Uri.parse('https://example.com/2/255')), isNull);
      expect(verseRefFromLink(Uri.parse('https://quran.com/2/999')), isNull);
      expect(verseRefFromLink(Uri.parse('https://quran.com/')), isNull);
    });
  });
}
