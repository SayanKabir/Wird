import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/quran/quran_meta.dart';
import 'package:wird2/core/quran/transliterator.dart';

/// Guards the bundled easy-reading transliteration. The source it came from
/// had verses holding another verse's text, phrases written twice, cut-off
/// endings, page markup and tripled letters; these checks keep them out.
void main() {
  final lines = File('assets/quran/transliteration_en.txt').readAsStringSync().split('\n');
  if (lines.last.isEmpty) lines.removeLast();

  String verse(int surah, int ayah) => lines[QuranMeta.globalIndex(surah, ayah)];

  test('one non-empty line per ayah', () {
    expect(lines, hasLength(QuranMeta.totalVerses));
    for (var i = 0; i < lines.length; i++) {
      expect(lines[i].trim(), isNotEmpty, reason: 'line ${i + 1}');
      expect(lines[i], lines[i].trim(), reason: 'line ${i + 1}');
    }
  });

  test('plain text only: no markup, tripled letters or stray characters', () {
    for (var i = 0; i < lines.length; i++) {
      final (s, v) = QuranMeta.fromGlobalIndex(i);
      final l = lines[i];
      expect(RegExp(r"[^A-Za-z' ;,.:!?\-]").hasMatch(l), isFalse, reason: '$s:$v "$l"');
      expect(RegExp(r'([b-df-hj-np-tv-z])\1\1', caseSensitive: false).hasMatch(l), isFalse, reason: '$s:$v "$l"');
      expect(RegExp(r'([aeiou])\1\1\1').hasMatch(l), isFalse, reason: '$s:$v "$l"');
      expect(RegExp(r';\S').hasMatch(l), isFalse, reason: '$s:$v "$l"');
    }
  });

  test('no phrase is written twice in a row', () {
    // The Arabic itself repeats these.
    const genuine = {'33:55'};
    for (var i = 0; i < lines.length; i++) {
      final (s, v) = QuranMeta.fromGlobalIndex(i);
      if (genuine.contains('$s:$v')) continue;
      final w = lines[i].replaceAll(RegExp(r'[;,.]'), '').toLowerCase().split(' ');
      for (var n = 4; n * 2 <= w.length; n++) {
        for (var a = 0; a + 2 * n <= w.length; a++) {
          final first = w.sublist(a, a + n).join(' ');
          expect(first == w.sublist(a + n, a + 2 * n).join(' '), isFalse, reason: '$s:$v repeats "$first"');
        }
      }
    }
  });

  test('lines sit on their own ayah', () {
    expect(verse(1, 1), 'Bismillaahir Rahmaanir Raheem');
    expect(verse(2, 1), 'Alif-Laaam-Meeem');
    expect(verse(2, 255), startsWith('Allahu laaa ilaaha illaa Huwal Haiyul Qaiyoom'));
    expect(verse(36, 1), startsWith('Yaa-Seeen'));
    expect(verse(112, 1), startsWith('Qul huwal laahu ahad'));
    expect(verse(114, 6), 'Minal jinnati wan naas');
  });

  test('verses that held the wrong text are corrected', () {
    expect(verse(37, 60), 'Inna haazaa lahuwal fawzul \'azeem');
    expect(verse(50, 19), contains('sakratul mawti'));
    expect(verse(50, 19), isNot(verse(50, 21)));
    expect(verse(27, 54), endsWith('tubsiroon'));
    expect(verse(17, 2), endsWith('min doonee wakeelaa'));
    expect(verse(4, 58), contains("ni'immaa ya'izukum"));
    expect('yaamurukum'.allMatches(verse(4, 58)), hasLength(1));
    expect(verse(5, 22), contains('fa iny yakhrujoo minhaa'));
    expect(verse(33, 22), contains('wa sadaqal laahu wa Rasooluh'));
    expect(verse(42, 12), endsWith("bikulli shai'in 'Aleem"));
  });

  test('every ayah converts cleanly to Hindi and Bangla script', () {
    final latin = RegExp('[a-z]', caseSensitive: false);
    for (final script in [TransliterationScript.devanagari, TransliterationScript.bengali]) {
      for (var i = 0; i < lines.length; i++) {
        final (s, v) = QuranMeta.fromGlobalIndex(i);
        final out = Transliterator.convert(lines[i], script);
        expect(out.trim(), isNotEmpty, reason: '$script $s:$v');
        expect(latin.hasMatch(out), isFalse, reason: '$script $s:$v "$out"');
        // Three of the same letter joined by viramas never occurs in either script.
        expect(RegExp(r'(\S)्\1्\1|(\S)্\2্\2').hasMatch(out), isFalse, reason: '$script $s:$v "$out"');
      }
    }
  });

  test('a tripled letter converts as a doubled one', () {
    for (final script in [TransliterationScript.devanagari, TransliterationScript.bengali]) {
      expect(Transliterator.convert('Jannnati', script), Transliterator.convert('Jannati', script));
    }
  });
}
