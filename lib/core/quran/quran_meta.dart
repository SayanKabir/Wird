/// Static structure of the Mushaf: verse counts, juz boundaries, and
/// parsing of verse references such as "2:255".
class QuranMeta {
  const QuranMeta._();

  static const int totalVerses = 6236;

  /// Number of ayahs in each surah, in Mushaf order.
  static const List<int> verseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30,
    20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4,
    5, 6,
  ];

  /// First ayah of each juz as (surah, verse), juz 1 → index 0.
  static const List<(int, int)> juzStarts = [
    (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111),
    (7, 88), (8, 41), (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75),
    (21, 1), (23, 1), (25, 21), (27, 56), (29, 46), (33, 31), (36, 28),
    (39, 32), (41, 47), (46, 1), (51, 31), (58, 1), (67, 1), (78, 1),
  ];

  static final List<int> _offsets = () {
    final offsets = List<int>.filled(115, 0);
    for (var i = 0; i < 114; i++) {
      offsets[i + 1] = offsets[i] + verseCounts[i];
    }
    return offsets;
  }();

  static bool isValid(int surah, int verse) =>
      surah >= 1 && surah <= 114 && verse >= 1 && verse <= verseCounts[surah - 1];

  /// 0-based position of an ayah in the whole Quran (1:1 → 0, 114:6 → 6235).
  static int globalIndex(int surah, int verse) => _offsets[surah - 1] + verse - 1;

  /// Range of global indices covering a surah: [start, end).
  static (int, int) surahRange(int surah) => (_offsets[surah - 1], _offsets[surah]);

  /// Inverse of [globalIndex].
  static (int, int) fromGlobalIndex(int index) {
    var surah = 1;
    while (surah < 114 && _offsets[surah] <= index) {
      surah++;
    }
    return (surah, index - _offsets[surah - 1] + 1);
  }

  static int juzOf(int surah, int verse) {
    final idx = globalIndex(surah, verse);
    for (var j = 29; j >= 0; j--) {
      final (s, v) = juzStarts[j];
      if (idx >= globalIndex(s, v)) return j + 1;
    }
    return 1;
  }

  /// Last ayah of a juz as (surah, verse).
  static (int, int) juzEnd(int juz) {
    if (juz >= 30) return (114, 6);
    final (s, v) = juzStarts[juz];
    return fromGlobalIndex(globalIndex(s, v) - 1);
  }

  /// Surahs that have at least one ayah inside the given juz, each with the
  /// verse range that falls inside it.
  static List<JuzSegment> juzSegments(int juz) {
    final (startS, startV) = juzStarts[juz - 1];
    final (endS, endV) = juzEnd(juz);
    return [
      for (var s = startS; s <= endS; s++)
        JuzSegment(
          surah: s,
          fromVerse: s == startS ? startV : 1,
          toVerse: s == endS ? endV : verseCounts[s - 1],
        ),
    ];
  }

  /// Parses verse references the way people type them:
  /// "2:255", "2 255", "2.255", "2-255", "2:255-257".
  /// Returns null if the text isn't a reference or points nowhere.
  static VerseRef? parseReference(String input) {
    final m = RegExp(r'^\s*(\d{1,3})\s*[:.\s\-/]\s*(\d{1,3})(?:\s*-\s*(\d{1,3}))?\s*$').firstMatch(input);
    if (m == null) return null;
    final surah = int.parse(m.group(1)!);
    final verse = int.parse(m.group(2)!);
    if (!isValid(surah, verse)) return null;
    final end = m.group(3) != null ? int.parse(m.group(3)!) : null;
    return VerseRef(surah, verse, toVerse: end != null && isValid(surah, end) && end > verse ? end : null);
  }

  /// "juz 5", "para 5", "j5" → 5.
  static int? parseJuz(String input) {
    final m = RegExp(r'^\s*(?:juz|juzz|para|parah|j)\s*(\d{1,2})\s*$', caseSensitive: false).firstMatch(input);
    if (m == null) return null;
    final n = int.parse(m.group(1)!);
    return n >= 1 && n <= 30 ? n : null;
  }
}

class VerseRef {
  final int surah;
  final int verse;
  final int? toVerse;

  const VerseRef(this.surah, this.verse, {this.toVerse});

  String get key => '$surah:$verse';

  @override
  String toString() => toVerse != null ? '$surah:$verse-$toVerse' : key;
}

class JuzSegment {
  final int surah;
  final int fromVerse;
  final int toVerse;

  const JuzSegment({required this.surah, required this.fromVerse, required this.toVerse});

  int get verseCount => toVerse - fromVerse + 1;
}
