import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/quran/quran_meta.dart';
import 'package:wird2/core/quran/surah_search.dart';
import 'package:wird2/core/quran/transliterator.dart';
import 'package:wird2/models/surah.dart';

Surah _surah(int id, String translit, String meaning, String arabic) => Surah(
      id: id,
      nameArabic: arabic,
      nameTranslation: meaning,
      nameTransliteration: translit,
      versesCount: QuranMeta.verseCounts[id - 1],
      revelationPlace: 'makkah',
      revelationOrder: id,
      pages: const [1, 1],
    );

void main() {
  final surahs = [
    _surah(1, 'Al-Fatihah', 'The Opener', 'الفاتحة'),
    _surah(2, 'Al-Baqarah', 'The Cow', 'البقرة'),
    _surah(18, 'Al-Kahf', 'The Cave', 'الكهف'),
    _surah(36, 'Ya-Sin', 'Ya Sin', 'يس'),
    _surah(55, 'Ar-Rahman', 'The Beneficent', 'الرحمن'),
    _surah(67, 'Al-Mulk', 'The Sovereignty', 'الملك'),
    _surah(78, 'An-Naba', 'The Tidings', 'النبإ'),
    _surah(112, 'Al-Ikhlas', 'The Sincerity', 'الإخلاص'),
  ];

  List<int> ids(String q) => SurahSearch.match(surahs, q).map((s) => s.id).toList();

  group('SurahSearch', () {
    test('an empty query lists everything', () {
      expect(ids(''), hasLength(surahs.length));
      expect(ids('   '), hasLength(surahs.length));
    });

    test('numbers match by surah number only', () {
      expect(ids('18'), [18]);
      expect(ids('999'), isEmpty);
    });

    test('spelling variants of a name all match', () {
      for (final q in ['baqara', 'baqarah', 'Al-Baqarah', 'al baqarah', 'AL-BAQARA']) {
        expect(ids(q), [2], reason: q);
      }
      expect(ids('fatiha'), [1]);
      expect(ids('kahf'), [18]);
      expect(ids('yasin'), [36]);
      expect(ids('rahman'), [55]);
      expect(ids('ikhlas'), [112]);
      expect(ids('naba'), [78]);
    });

    test('meanings and Arabic names match', () {
      expect(ids('cave'), [18]);
      expect(ids('the cow'), [2]);
      expect(ids('الملك'), [67]);
    });

    test('nonsense matches nothing', () {
      expect(ids('zzzz'), isEmpty);
    });

    test('fold strips punctuation, articles and long vowels', () {
      expect(SurahSearch.fold('Al-Baqarah'), 'baqara');
      expect(SurahSearch.fold('An-Naas'), 'nas');
      expect(SurahSearch.fold('At-Takweer'), 'takwir');
      // Short names keep their leading letters.
      expect(SurahSearch.fold('Alaq'), 'alaq');
    });
  });

  group('QuranMeta edge cases', () {
    test('there are 114 surahs and 6236 ayat', () {
      expect(QuranMeta.verseCounts, hasLength(114));
      expect(QuranMeta.verseCounts.reduce((a, b) => a + b), QuranMeta.totalVerses);
      expect(QuranMeta.juzStarts, hasLength(30));
    });

    test('validity at the edges', () {
      expect(QuranMeta.isValid(1, 1), isTrue);
      expect(QuranMeta.isValid(1, 7), isTrue);
      expect(QuranMeta.isValid(114, 6), isTrue);
      expect(QuranMeta.isValid(0, 1), isFalse);
      expect(QuranMeta.isValid(1, 0), isFalse);
      expect(QuranMeta.isValid(114, 7), isFalse);
    });

    test('first and last ayah', () {
      expect(QuranMeta.globalIndex(1, 1), 0);
      expect(QuranMeta.globalIndex(114, 6), QuranMeta.totalVerses - 1);
      expect(QuranMeta.fromGlobalIndex(0), (1, 1));
      expect(QuranMeta.fromGlobalIndex(QuranMeta.totalVerses - 1), (114, 6));
      expect(QuranMeta.juzOf(1, 1), 1);
      expect(QuranMeta.juzOf(114, 6), 30);
      expect(QuranMeta.juzEnd(30), (114, 6));
    });

    test('each juz ends right before the next begins', () {
      for (var j = 1; j < 30; j++) {
        final (s, v) = QuranMeta.juzEnd(j);
        expect(QuranMeta.juzOf(s, v), j);
        final (ns, nv) = QuranMeta.juzStarts[j];
        expect(QuranMeta.globalIndex(ns, nv), QuranMeta.globalIndex(s, v) + 1);
      }
    });

    test('a range that runs backwards or off the end is dropped', () {
      expect(QuranMeta.parseReference('2:255-250')?.toVerse, isNull);
      expect(QuranMeta.parseReference('1:5-9')?.toVerse, isNull);
      expect(QuranMeta.parseReference('2:255')!.toString(), '2:255');
      expect(QuranMeta.parseReference('2:255-257')!.toString(), '2:255-257');
      expect(QuranMeta.parseReference('2/255')?.key, '2:255');
    });

    test('juz parsing rejects out-of-range numbers', () {
      expect(QuranMeta.parseJuz('juz 0'), isNull);
      expect(QuranMeta.parseJuz('juz 31'), isNull);
      expect(QuranMeta.parseJuz('j1'), 1);
      expect(QuranMeta.parseJuz('parah 30'), 30);
      expect(QuranMeta.parseJuz('30'), isNull);
    });
  });

  group('TransliterationScript', () {
    test('keys round-trip and unknown keys fall back to Latin', () {
      for (final s in TransliterationScript.values) {
        expect(TransliterationScript.fromKey(s.key), s);
        expect(s.label, isNotEmpty);
      }
      expect(TransliterationScript.fromKey(null), TransliterationScript.latin);
      expect(TransliterationScript.fromKey('klingon'), TransliterationScript.latin);
    });

    test('conversion never throws on odd input', () {
      for (final s in TransliterationScript.values) {
        for (final input in ['', ' ', "'", '-', 'a', 'Q', '123', "Al-Hamdu lillaahi Rabbil-'aalameen"]) {
          expect(() => Transliterator.convert(input, s), returnsNormally, reason: '$s "$input"');
        }
      }
    });
  });
}
