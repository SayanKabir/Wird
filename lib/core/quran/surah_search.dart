import '../../models/surah.dart';

/// Surah lookup shared by the Quran tab search and the reader's Go to sheet.
class SurahSearch {
  const SurahSearch._();

  /// Surahs matching by number, name or meaning. Names are compared with
  /// punctuation and the "Al-" prefix folded away, so "baqara",
  /// "al baqarah" and "Al-Baqarah" all match.
  static List<Surah> match(List<Surah> surahs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    final number = int.tryParse(q);
    if (number != null) return surahs.where((s) => s.id == number).toList();
    // Arabic or other non-Latin text folds to nothing, which every name
    // "contains"; skip the Latin comparison then.
    final folded = fold(q);
    return surahs.where((s) {
      return (folded.isNotEmpty && fold(s.nameTransliteration).contains(folded)) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(query.trim());
    }).toList();
  }

  /// Surah name in comparable form: letters only, common article prefixes
  /// dropped, doubled vowels and a trailing h folded.
  static String fold(String s) {
    var out = s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (out.startsWith('al') && out.length > 4) out = out.substring(2);
    if (out.startsWith('an') && out.length > 5) out = out.substring(2);
    if (out.startsWith('at') && out.length > 5) out = out.substring(2);
    return out.replaceAll('aa', 'a').replaceAll('ee', 'i').replaceAll('oo', 'u').replaceAll(RegExp(r'h$'), '');
  }
}
