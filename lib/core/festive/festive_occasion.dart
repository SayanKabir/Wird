import 'package:flutter/widgets.dart';

import '../../widgets/common/festive_canopy.dart';
import '../utils/hijri_date.dart';
import '../utils/islamic_day_utils.dart';

/// How loudly the app celebrates.
enum FestiveTier {
  /// All of Ramadan: lanterns in the sky and festive accents. Present but
  /// calm, since it lasts a month.
  ramadan,

  /// Eid al-Fitr, Eid al-Adha and Arafah: everything above, plus gold
  /// bursts in the sky and a greeting on the day's first open.
  celebration,
}

/// Today's occasion, if it's one the whole app dresses up for. Uses the same
/// rule as the calendar's lanterns ([IslamicDayUtils.canopyFor]), so the
/// app and the calendar always agree.
class FestiveOccasion {
  final IslamicEventType type;
  final FestiveTier tier;
  final CanopyMood mood;
  final HijriDate hijri;

  const FestiveOccasion({required this.type, required this.tier, required this.mood, required this.hijri});

  /// Build with `--dart-define=WIRD_FESTIVE=ramadan` (or `eid`, `arafah`)
  /// to preview the decorations on an ordinary day.
  static const String _preview = String.fromEnvironment('WIRD_FESTIVE');

  /// Null on ordinary days, and whenever Islamic occasions are turned off.
  static FestiveOccasion? today({DateTime? maghribTime, required bool enabled}) {
    if (!enabled) return null;
    final now = DateTime.now();
    final hijri = HijriDate.fromDateTime(now, maghribTime: maghribTime);
    if (_preview.isNotEmpty) return _previewOccasion(hijri);

    final mood = IslamicDayUtils.canopyFor(now, maghribTime: maghribTime);
    final message = IslamicDayUtils.messageForDate(now, maghribTime: maghribTime);
    if (mood == null || message == null) return null;
    final ramadan = message.type == IslamicEventType.ramadan || message.type == IslamicEventType.laylatAlQadr;
    return FestiveOccasion(
      type: message.type,
      tier: ramadan ? FestiveTier.ramadan : FestiveTier.celebration,
      mood: mood,
      hijri: hijri,
    );
  }

  static FestiveOccasion _previewOccasion(HijriDate hijri) => switch (_preview) {
        'eid' => FestiveOccasion(
            type: IslamicEventType.eidAlFitr, tier: FestiveTier.celebration, mood: CanopyMood.celebration, hijri: hijri),
        'arafah' => FestiveOccasion(
            type: IslamicEventType.arafah, tier: FestiveTier.celebration, mood: CanopyMood.celebration, hijri: hijri),
        _ => FestiveOccasion(
            type: IslamicEventType.ramadan, tier: FestiveTier.ramadan, mood: CanopyMood.night, hijri: hijri),
      };

  /// The line the app greets you with today.
  String get greeting => switch (type) {
        IslamicEventType.eidAlFitr || IslamicEventType.eidAlAdha => 'Eid Mubarak',
        IslamicEventType.arafah => 'Day of Arafah',
        _ => 'Ramadan Kareem',
      };

  /// A second line for the full-screen greeting.
  String get blessing => switch (type) {
        IslamicEventType.eidAlFitr || IslamicEventType.eidAlAdha =>
          'Taqabbal Allahu minna wa minkum',
        IslamicEventType.arafah => 'The best duʿa is the duʿa of Arafah',
        _ => 'May this month bring you closer',
      };

  /// Shown once per occasion day, keyed by its Hijri date.
  String get greetingKey => 'festive_greeting_${hijri.year}_${hijri.month}_${hijri.day}';

  @override
  bool operator ==(Object other) =>
      other is FestiveOccasion && other.type == type && other.tier == tier && other.hijri.day == hijri.day;

  @override
  int get hashCode => Object.hash(type, tier, hijri.day);
}

/// Hands today's [FestiveOccasion] to every tab, so pages can add their own
/// small touches without working it out again.
class FestiveScope extends InheritedWidget {
  final FestiveOccasion? occasion;

  const FestiveScope({super.key, required this.occasion, required super.child});

  static FestiveOccasion? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FestiveScope>()?.occasion;

  @override
  bool updateShouldNotify(FestiveScope old) => old.occasion != occasion;
}
