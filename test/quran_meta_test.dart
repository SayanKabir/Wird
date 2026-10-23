import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/quran/quran_meta.dart';
import 'package:wird2/core/quran/transliterator.dart';

void main() {
  group('QuranMeta.parseReference', () {
    test('accepts common separators', () {
      for (final input in ['2:255', '2 255', '2.255', '2-255', ' 2 : 255 ']) {
        final ref = QuranMeta.parseReference(input);
        expect(ref?.surah, 2, reason: input);
        expect(ref?.verse, 255, reason: input);
      }
    });

    test('parses ranges', () {
      final ref = QuranMeta.parseReference('2:255-257');
      expect(ref?.toVerse, 257);
    });

    test('rejects verses that do not exist', () {
      expect(QuranMeta.parseReference('1:8'), isNull);
      expect(QuranMeta.parseReference('115:1'), isNull);
      expect(QuranMeta.parseReference('baqarah'), isNull);
    });
  });

  group('QuranMeta juz', () {
    test('parses juz queries', () {
      expect(QuranMeta.parseJuz('juz 30'), 30);
      expect(QuranMeta.parseJuz('Para 5'), 5);
      expect(QuranMeta.parseJuz('juz 31'), isNull);
    });

    test('maps verses to juz', () {
      expect(QuranMeta.juzOf(1, 1), 1);
      expect(QuranMeta.juzOf(2, 141), 1);
      expect(QuranMeta.juzOf(2, 142), 2);
      expect(QuranMeta.juzOf(114, 6), 30);
    });

    test('segments cover each juz', () {
      final seg = QuranMeta.juzSegments(3);
      expect(seg.first.surah, 2);
      expect(seg.first.fromVerse, 253);
      expect(seg.last.surah, 3);
      expect(seg.last.toVerse, 92);
      final total = [for (var j = 1; j <= 30; j++) ...QuranMeta.juzSegments(j)]
          .fold<int>(0, (sum, s) => sum + s.verseCount);
      expect(total, QuranMeta.totalVerses);
    });

    test('global index round-trips', () {
      expect(QuranMeta.globalIndex(1, 1), 0);
      expect(QuranMeta.globalIndex(114, 6), 6235);
      expect(QuranMeta.fromGlobalIndex(QuranMeta.globalIndex(36, 12)), (36, 12));
    });
  });

  group('Transliterator', () {
    test('Devanagari', () {
      expect(
        Transliterator.convert('Bismillaahir Rahmaanir Raheem', TransliterationScript.devanagari),
        'बिस्मिल्लाहिर रहमानिर रहीम',
      );
      expect(
        Transliterator.convert('Ar-Rahmaanir-Raheem', TransliterationScript.devanagari),
        'अर्रहमानिर्रहीम',
      );
    });

    test('Bengali', () {
      expect(
        Transliterator.convert('Qul huwal laahu ahad', TransliterationScript.bengali),
        'কুল হুওয়াল লাহু আহাদ',
      );
      expect(
        Transliterator.convert('Alif-Laaam-Meeem', TransliterationScript.bengali),
        'আলিফ-লাম-মীম',
      );
    });

    test('Latin passes through', () {
      const s = "Alhamdu lillaahi Rabbil 'aalameen";
      expect(Transliterator.convert(s, TransliterationScript.latin), s);
    });
  });
}
