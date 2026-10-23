/// Transliteration scripts the reader can show under each ayah.
enum TransliterationScript {
  latin,
  devanagari,
  bengali;

  String get label {
    switch (this) {
      case TransliterationScript.latin:
        return 'English';
      case TransliterationScript.devanagari:
        return 'हिन्दी';
      case TransliterationScript.bengali:
        return 'বাংলা';
    }
  }

  String get key => name;

  static TransliterationScript fromKey(String? key) {
    return TransliterationScript.values.firstWhere(
      (s) => s.key == key,
      orElse: () => TransliterationScript.latin,
    );
  }
}

/// Converts the bundled easy-reading English transliteration
/// ("Bismillaahir Rahmaanir Raheem") into Devanagari or Bengali script, the
/// way Hindi and Bangla Quran prints write it ("बिस्मिल्लाहिर रहमानिर रहीम",
/// "বিসমিল্লাহির রাহমানির রাহীম").
///
/// The source spelling is regular enough to convert phonetically: doubled
/// vowels are long ("aa", "ee", "oo"), an apostrophe or hyphen marks a
/// glottal break, and tajweed joins are already spelled out by the source.
class Transliterator {
  const Transliterator._();

  static String convert(String latin, TransliterationScript script) {
    if (script == TransliterationScript.latin) return latin;
    final table = script == TransliterationScript.devanagari ? _devanagari : _bengali;
    return latin.toLowerCase().replaceAllMapped(
          RegExp(r"[a-z'\-]+"),
          (m) => _word(m.group(0)!, table),
        );
  }

  // ── Tokenising ──────────────────────────────────────────────────────────

  static bool _isVowelChar(String c) => 'aeiou'.contains(c);

  /// Splits a word into phonetic units: consonant keys ("b", "kh", "sh"…),
  /// vowel keys ("a", "A" long, "I", "U", "E" = ai, "O" = au) and "'" breaks.
  static List<String> _tokens(String w) {
    // The source spells the Name "Allah" with a short a; it's recited long.
    w = w.replaceFirst(RegExp(r'^allah'), 'allaah');
    // Tanween markers the source writes before a following "w"/"m" sound.
    w = w.replaceAll(RegExp(r'(?<=[nm])w+$'), '').replaceAll('mww', 'm');
    final out = <String>[];
    var i = 0;
    String at(int j) => j < w.length ? w[j] : '';
    bool startsWith(String s) => w.startsWith(s, i);

    while (i < w.length) {
      final c = w[i];
      if (c == "'") {
        out.add("'");
        i++;
        continue;
      }
      if (c == '-') {
        // Across a doubled letter a hyphen is a tajweed join ("Ar-Rahmaan" →
        // arrahmaan). Before a vowel it starts a fresh syllable ("Qur-aan").
        // Anywhere else it stays visible ("Siraatal-Mustaqeem", "Alif-Laam").
        // (Not after a long vowel — that's a letter name, "Laaam-Meeem".)
        final longBefore = i >= 3 && w[i - 2] == w[i - 3];
        final doubled = !longBefore && out.isNotEmpty && i + 1 < w.length && w[i + 1] == w[i - 1];
        if (_isVowelChar(at(i + 1))) {
          out.add('-');
        } else if (!doubled) {
          out.add('~');
        }
        i++;
        continue;
      }
      if (_isVowelChar(c)) {
        if (startsWith('aaa')) { out.add('A'); i += 3; continue; }
        if (startsWith('aa')) { out.add('A'); i += 2; continue; }
        if (startsWith('eee')) { out.add('I'); i += 3; continue; }
        if (startsWith('ee') || startsWith('ii')) { out.add('I'); i += 2; continue; }
        if (startsWith('ooo')) { out.add('U'); i += 3; continue; }
        if (startsWith('oo') || startsWith('uu')) { out.add('U'); i += 2; continue; }
        if (c == 'a' && (at(i + 1) == 'i' || at(i + 1) == 'y' || at(i + 1) == 'u' || at(i + 1) == 'w')) {
          // Diphthong only when the glide closes the syllable ("bai-na",
          // "nawm"); before a vowel it's a consonant ("ha-yyul", "a-wal").
          final next = at(i + 2);
          final closes = next.isEmpty || !(_isVowelChar(next) || next == 'y' || next == 'w');
          if (closes) {
            out.add(at(i + 1) == 'i' || at(i + 1) == 'y' ? 'E' : 'O');
            i += 2;
            continue;
          }
          out.add('a');
          i++;
          // "ai"/"au" followed by a vowel: the i/u acts as y/w.
          if (at(i) == 'i') { out.add('y'); i++; }
          if (at(i) == 'u') { out.add('w'); i++; }
          continue;
        }
        out.add(c == 'e' ? 'e' : c == 'o' ? 'o' : c);
        i++;
        continue;
      }
      if (startsWith('kh') || startsWith('gh') || startsWith('sh') || startsWith('zh')) {
        out.add(w.substring(i, i + 2));
        i += 2;
        continue;
      }
      // Word-initial "th" is ث ("thumma"); elsewhere it's t + h ("asaabat-hum").
      if (i == 0 && startsWith('th')) {
        out.add('th');
        i += 2;
        continue;
      }
      out.add(c);
      i++;
    }
    return out;
  }

  static bool _isBreak(String t) => t == "'" || t == '-' || t == '~';

  static bool _isVowel(String t) => t.length == 1 && 'aAiIuUEOeo'.contains(t);

  // ── Rendering ───────────────────────────────────────────────────────────

  static String _word(String w, _ScriptTable t) {
    final tokens = _tokens(w);
    final sb = StringBuffer();
    String? prev; // previous token, null at word start

    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      final next = i + 1 < tokens.length ? tokens[i + 1] : null;
      final prevIsConsonant = prev != null && !_isBreak(prev) && !_isVowel(prev);

      if (tok == '-' || tok == '~') {
        if (tok == '~') sb.write('-');
        prev = '-';
        continue;
      }
      if (tok == "'") {
        // A break before a vowel just makes that vowel independent; a break
        // that closes a syllable ("ya'lamu") is written with the script's
        // glottal mark. At word edges it's silent.
        if (prev != null && next != null && !_isVowel(next)) sb.write(t.glottal);
        prev = "'";
        continue;
      }

      if (_isVowel(tok)) {
        sb.write(prevIsConsonant ? t.signs[tok]! : t.independent[tok]!);
        prev = tok;
        continue;
      }

      // Consonant.
      if (t.custom != null) {
        final consumed = t.custom!(tok, prev, next, sb);
        if (consumed > 0) {
          i += consumed - 1;
          prev = consumed > 1 ? tokens[i] : tok;
          continue;
        }
      }
      if (prevIsConsonant && prev != 'h' && tok != 'h') sb.write(t.virama);
      sb.write(t.consonants[tok] ?? '');
      prev = tok;
    }
    return sb.toString();
  }

  static const _devanagari = _ScriptTable(
    consonants: {
      'b': 'ब', 't': 'त', 'th': 'स', 'j': 'ज', 'h': 'ह', 'kh': 'ख़', 'd': 'द',
      'z': 'ज़', 'zh': 'ज़', 'r': 'र', 's': 'स', 'sh': 'श', 'f': 'फ़', 'q': 'क़',
      'k': 'क', 'l': 'ल', 'm': 'म', 'n': 'न', 'w': 'व', 'y': 'य', 'g': 'ग',
      'gh': 'ग़', 'c': 'क', 'x': 'क्स', 'p': 'प', 'v': 'व',
    },
    independent: {
      'a': 'अ', 'A': 'आ', 'i': 'इ', 'I': 'ई', 'u': 'उ', 'U': 'ऊ',
      'E': 'ऐ', 'O': 'औ', 'e': 'ए', 'o': 'ओ',
    },
    signs: {
      'a': '', 'A': 'ा', 'i': 'ि', 'I': 'ी', 'u': 'ु', 'U': 'ू',
      'E': 'ै', 'O': 'ौ', 'e': 'े', 'o': 'ो',
    },
    virama: '्',
    glottal: 'अ',
  );

  static const _bengali = _ScriptTable(
    consonants: {
      'b': 'ব', 't': 'ত', 'th': 'স', 'j': 'জ', 'h': 'হ', 'kh': 'খ', 'd': 'দ',
      'z': 'য', 'zh': 'য', 'r': 'র', 's': 'স', 'sh': 'শ', 'f': 'ফ', 'q': 'ক',
      'k': 'ক', 'l': 'ল', 'm': 'ম', 'n': 'ন', 'w': 'ও', 'y': 'য়', 'g': 'গ',
      'gh': 'গ', 'c': 'ক', 'x': 'ক্স', 'p': 'প', 'v': 'ভ',
    },
    // Bangla Quran prints write the short "a" with আ/া, since the bare
    // inherent vowel reads as "o" in Bengali.
    independent: {
      'a': 'আ', 'A': 'আ', 'i': 'ই', 'I': 'ঈ', 'u': 'উ', 'U': 'ঊ',
      'E': 'আই', 'O': 'আও', 'e': 'এ', 'o': 'ও',
    },
    signs: {
      'a': 'া', 'A': 'া', 'i': 'ি', 'I': 'ী', 'u': 'ু', 'U': 'ূ',
      'E': 'াই', 'O': 'াও', 'e': 'ে', 'o': 'ো',
    },
    virama: '্',
    glottal: '\'',
    custom: _bengaliGlides,
  );

  /// Bengali has no plain letter for w, and y needs a carrier at a syllable
  /// start, so these are spelled the way Bangla prints do: "wa" → ওয়া,
  /// "ya" → ইয়া, "yy" → য়্য.
  static int _bengaliGlides(String tok, String? prev, String? next, StringBuffer sb) {
    final prevIsVowel = prev != null && _isVowel(prev);
    final prevIsConsonant = prev != null && !_isBreak(prev) && !_isVowel(prev);
    if (tok == 'w') {
      if (prevIsConsonant && prev != 'h' && prev != 'w') sb.write('্');
      switch (next) {
        case 'a':
        case 'A':
          sb.write('ওয়া');
          return 2;
        case 'i':
          sb.write('উই');
          return 2;
        case 'I':
          sb.write('উঈ');
          return 2;
        case 'u':
          sb.write('উ');
          return 2;
        case 'U':
          sb.write('ঊ');
          return 2;
        default:
          sb.write('ও');
          return 1;
      }
    }
    if (tok == 'y') {
      if (prevIsConsonant) {
        sb.write('্য');
        return 1;
      }
      if (!prevIsVowel && next != null && _isVowel(next)) {
        // Word or syllable start: ইয় + vowel sign.
        sb.write('ইয়');
        return 1;
      }
      sb.write('য়');
      return 1;
    }
    return 0;
  }
}

class _ScriptTable {
  final Map<String, String> consonants;
  final Map<String, String> independent;
  final Map<String, String> signs;
  final String virama;
  final String glottal;
  final int Function(String tok, String? prev, String? next, StringBuffer sb)? custom;

  const _ScriptTable({
    required this.consonants,
    required this.independent,
    required this.signs,
    required this.virama,
    required this.glottal,
    this.custom,
  });
}
