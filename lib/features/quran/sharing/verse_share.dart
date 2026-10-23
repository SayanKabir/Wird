import '../../../core/quran/quran_meta.dart';
import '../../../models/surah.dart';
import '../../../models/verse.dart';

/// A set of ayahs from one surah, prepared for sharing.
class VerseShare {
  final Surah surah;

  /// Selected ayahs in verse order.
  final List<Verse> verses;

  VerseShare({required this.surah, required List<Verse> verses})
    : verses = [...verses]
        ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

  int get first => verses.first.verseNumber;
  int get last => verses.last.verseNumber;

  /// Contiguous runs, e.g. ayahs 1,2,3,7 → [(1,3), (7,7)].
  List<(int, int)> get ranges {
    final out = <(int, int)>[];
    for (final v in verses) {
      final n = v.verseNumber;
      if (out.isNotEmpty && out.last.$2 == n - 1) {
        out[out.length - 1] = (out.last.$1, n);
      } else {
        out.add((n, n));
      }
    }
    return out;
  }

  /// "2:255", "2:255–257", or "2:255–257, 260" for gaps.
  String get reference {
    final parts = ranges
        .map((r) => r.$1 == r.$2 ? '${r.$1}' : '${r.$1}–${r.$2}')
        .join(', ');
    return '${surah.id}:$parts';
  }

  /// "Al-Baqarah 2:255–257"
  String get title => '${surah.nameTransliteration} $reference';

  /// Quran.com link covering the selection. Quran.com takes a single range,
  /// so a selection with gaps links to the span from first to last.
  Uri get link => Uri.parse(
    first == last
        ? 'https://quran.com/${surah.id}/$first'
        : 'https://quran.com/${surah.id}/$first-$last',
  );

  /// Plain-text version for messaging apps.
  String toText({bool translation = true, bool transliteration = false}) {
    final sb = StringBuffer();
    final multiple = verses.length > 1;
    for (final v in verses) {
      if (sb.isNotEmpty) sb.write('\n\n');
      sb.write(v.textUthmani.trim());
      if (multiple) sb.write(' (${v.verseNumber})');
      if (transliteration && (v.transliterationText ?? '').isNotEmpty) {
        sb.write('\n\n${v.transliterationText!.trim()}');
      }
      if (translation && (v.translationText ?? '').isNotEmpty) {
        sb.write(
          '\n\n${multiple ? '${v.verseNumber}. ' : ''}${v.translationText!.trim()}',
        );
      }
    }
    final source = translation ? verses.first.translationName : null;
    sb.write('\n\n— Quran, $title${source != null ? ' · $source' : ''}');
    sb.write('\n$link');
    return sb.toString();
  }
}

/// Reads a verse reference out of a quran.com link, e.g.
/// https://quran.com/2/255, /2/255-257, /2:255, /2?startingVerse=255,
/// /al-baqarah/255. Returns null for links that don't point at an ayah.
VerseRef? verseRefFromLink(Uri uri, {List<Surah> surahs = const []}) {
  final host = uri.host.toLowerCase();
  if (host != 'quran.com' && host != 'www.quran.com') return null;

  var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  // Locale prefixes such as /en/2/255.
  if (segments.isNotEmpty && RegExp(r'^[a-z]{2}$').hasMatch(segments.first)) {
    segments = segments.sublist(1);
  }
  if (segments.isEmpty) return null;

  int? surah;
  int? verse;
  int? toVerse;

  final head = segments.first;
  final colon = RegExp(
    r'^(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?$',
  ).firstMatch(head);
  if (colon != null) {
    surah = int.parse(colon.group(1)!);
    verse = int.parse(colon.group(2)!);
    toVerse = colon.group(3) != null ? int.parse(colon.group(3)!) : null;
  } else {
    surah = int.tryParse(head);
    // Named pages quran.com redirects well-known ayahs to.
    const named = {'ayatul-kursi': (2, 255)};
    final known = named[head.toLowerCase()];
    if (known != null) return VerseRef(known.$1, known.$2);
    if (surah == null) {
      // Slug form: /al-baqarah/255
      final slug = head.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      for (final s in surahs) {
        if (s.nameTransliteration.toLowerCase().replaceAll(
              RegExp(r'[^a-z]'),
              '',
            ) ==
            slug) {
          surah = s.id;
          break;
        }
      }
    }
    if (segments.length > 1) {
      final m = RegExp(r'^(\d{1,3})(?:-(\d{1,3}))?$').firstMatch(segments[1]);
      if (m != null) {
        verse = int.parse(m.group(1)!);
        toVerse = m.group(2) != null ? int.parse(m.group(2)!) : null;
      }
    }
    verse ??= int.tryParse(uri.queryParameters['startingVerse'] ?? '');
  }

  if (surah == null) return null;
  verse ??= 1;
  if (!QuranMeta.isValid(surah, verse)) return null;
  return VerseRef(
    surah,
    verse,
    toVerse:
        toVerse != null && toVerse > verse && QuranMeta.isValid(surah, toVerse)
            ? toVerse
            : null,
  );
}
