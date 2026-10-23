import 'package:flutter/material.dart';

import '../../../models/sunnah.dart';
import '../../tasbih/screens/tasbih_screen.dart';

/// Display helpers shared by the Sunnah screen and its detail sheet.
///
/// The stored category names double as part of each sunnah's id, so they stay
/// as they are in the data; these helpers only shorten them for the UI.
class SunnahFormat {
  SunnahFormat._();

  /// Order the categories appear in the library.
  static const List<String> categoryOrder = [
    'Masjid & Prayer',
    'Dhikr & Azkar',
    'Sleep & Waking',
    'Eating & Drinking',
    'Social Etiquette & Character',
    'Family & Relationships',
    'Personal Hygiene',
    'Fasting',
    'Charity & Generosity',
    'Knowledge',
    'Travel',
    'Miscellaneous Daily Sunnahs',
  ];

  static const Map<String, String> _shortCategory = {
    'Masjid & Prayer': 'Prayer',
    'Dhikr & Azkar': 'Dhikr',
    'Sleep & Waking': 'Sleep',
    'Eating & Drinking': 'Eating',
    'Social Etiquette & Character': 'Character',
    'Family & Relationships': 'Family',
    'Personal Hygiene': 'Hygiene',
    'Fasting': 'Fasting',
    'Charity & Generosity': 'Charity',
    'Knowledge': 'Knowledge',
    'Travel': 'Travel',
    'Miscellaneous Daily Sunnahs': 'Daily life',
  };

  static String shortCategory(String category) =>
      _shortCategory[category] ?? category;

  /// Full category name for the sheet's overline ("SLEEP AND WAKING").
  static String categoryOverline(String category) =>
      category.replaceAll('&', 'and').toUpperCase();

  static int categoryIndex(String category) {
    final i = categoryOrder.indexOf(category);
    return i < 0 ? categoryOrder.length : i;
  }

  /// "Bukhari 5376, Muslim 2017"
  static String reference(Sunnah sunnah) => sunnah.reference['hadith'] ?? '';

  /// Shorter form for list rows: only the first source.
  static String shortReference(Sunnah sunnah) =>
      reference(sunnah).split(',').first.trim();

  /// "Bukhari 5376, Muslim 2017 · Sahih"
  static String fullReference(Sunnah sunnah) {
    final grade = sunnah.reference['grade'];
    final ref = reference(sunnah);
    if (grade == null || grade.isEmpty) return ref;
    return ref.isEmpty ? grade : '$ref · $grade';
  }

  /// The description without its trailing "(Bukhari 5376)", since the
  /// reference is shown on its own line.
  static String description(Sunnah sunnah) {
    return sunnah.description
        .replaceFirst(RegExp(r'\s*\([^()]*\d[^()]*\)\s*\.?\s*$'), '')
        .trim();
  }

  /// "Today", "Yesterday", "Tuesday" (within a week) or "12 Oct".
  static String relativeDay(String dateKey, {DateTime? now}) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return dateKey;
    final today = now ?? DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(parsed.year, parsed.month, parsed.day))
        .inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (days > 1 && days < 7) return weekdays[parsed.weekday - 1];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${parsed.day} ${months[parsed.month - 1]}';
  }

  static bool hasTasbih(Sunnah sunnah) => sunnah.tasbihId != null;

  /// Opens the Tasbih counter set up for a dhikr sunnah.
  ///
  /// The "33 times after prayer" sunnahs each have their own counter, so they
  /// open it directly rather than the after-prayer flow, which starts on
  /// Astaghfirullah.
  static void openTasbih(BuildContext context, Sunnah sunnah) {
    final title = sunnah.title.toLowerCase();
    String? flow;
    if (title.contains('fatimah')) {
      flow = 'fatimah';
    } else if (title.contains('before sleep') || title.contains('before-sleep')) {
      flow = 'before_sleep';
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbihScreen(
          initialTasbihId: sunnah.tasbihId,
          initialQuery: sunnah.title,
          initialFlow: flow,
          sourceSunnah: sunnah,
        ),
      ),
    );
  }
}
