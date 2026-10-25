import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/effects.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../core/utils/hijri_date.dart';
import '../../../core/utils/islamic_day_utils.dart';
import '../../../widgets/common/string_lights_overlay.dart';
import '../../../widgets/common/page_header.dart';
import '../../../widgets/common/pressable.dart';
import '../../../core/services/haptic_service.dart';

/// The Hijri calendar: a month grid with Hijri dates leading, a detail card
/// for whichever day is selected, and the month's occasions underneath.
///
/// Swipe the grid sideways to change month; "Today" brings you back.
class IslamicCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;
  final PrayerPeriod prayerPeriod;
  final DateTime? maghribTime;

  const IslamicCalendarScreen({
    super.key,
    this.initialDate,
    this.prayerPeriod = PrayerPeriod.isha,
    this.maghribTime,
  });

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

/// The grid treats a Gregorian day as the Hijri date that began at the
/// previous evening's Maghrib, so most of the daylight hours line up.
HijriDate _hijriFor(DateTime date) =>
    HijriDate.fromGregorian(date.subtract(const Duration(days: 1)));

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  /// +1 when the last month change went forward, -1 when back. Drives which
  /// way the grid slides.
  int _direction = 1;

  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final seed = widget.initialDate ?? now;
    _focusedMonth = DateTime(seed.year, seed.month, 1);
    _selectedDate = DateTime(seed.year, seed.month, seed.day);
  }

  void _changeMonth(int delta) {
    HapticService().selection();
    setState(() {
      _direction = delta;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  void _select(DateTime date) {
    HapticService().selection();
    setState(() {
      _selectedDate = date;
      if (date.month != _focusedMonth.month || date.year != _focusedMonth.year) {
        _direction = date.isAfter(_focusedMonth) ? 1 : -1;
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  void _goToToday() {
    HapticService().light();
    setState(() {
      _direction = _today.isAfter(_focusedMonth) ? 1 : -1;
      _focusedMonth = DateTime(_today.year, _today.month, 1);
      _selectedDate = _today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final gutter = AppSpacing.gutter(context);
    final gradientColors = AppColors.getGradientForPeriod(widget.prayerPeriod);
    final hasSpecialDay =
        IslamicDayUtils.messageForDate(DateTime.now(), maghribTime: widget.maghribTime) != null;
    final atToday = _sameDay(_selectedDate, _today) &&
        _focusedMonth.month == _today.month &&
        _focusedMonth.year == _today.year;
    final animate = AppEffects.entranceMotion;

    Widget enter(Widget child, int order) => animate
        ? child
            .animate()
            .fadeIn(delay: (order * 70).ms, duration: 380.ms)
            .slideY(begin: 0.04, curve: Curves.easeOutCubic)
        : child;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Container(
        // A dark veil over the sky gradient so the grid reads the same at
        // noon as at night.
        color: Colors.black.withValues(alpha: 0.28),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                if (hasSpecialDay)
                  Positioned(
                    top: screenHeight * 0.02,
                    left: 0,
                    right: 0,
                    height: screenHeight * 0.18,
                    child: const StringLightsOverlay(),
                  ),
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, AppSpacing.belowHeader),
                        child: PageHeader(
                          overline: 'ISLAMIC CALENDAR',
                          title: 'Calendar',
                          overlineColor: AppColors.kaabaGold.withValues(alpha: 0.85),
                          onBack: () => Navigator.of(context).pop(),
                          trailing: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: atToday
                                ? const SizedBox.shrink()
                                : _TodayChip(onTap: _goToToday),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      sliver: SliverToBoxAdapter(
                        child: enter(
                          _MonthGrid(
                            focusedMonth: _focusedMonth,
                            selectedDate: _selectedDate,
                            today: _today,
                            direction: _direction,
                            onMonthChanged: _changeMonth,
                            onDateSelected: _select,
                          ),
                          0,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: enter(
                          _DayDetail(
                            date: _selectedDate,
                            isToday: _sameDay(_selectedDate, _today),
                            maghribTime: widget.maghribTime,
                          ),
                          1,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.section, gutter, 120),
                      sliver: SliverToBoxAdapter(
                        child: enter(
                          _MonthEvents(
                            focusedMonth: _focusedMonth,
                            selectedDate: _selectedDate,
                            onSelect: _select,
                          ),
                          2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TODAY CHIP
// =============================================================================

class _TodayChip extends StatelessWidget {
  final VoidCallback onTap;

  const _TodayChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: PressableHaptic.none,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kaabaGold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.kaabaGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.today_rounded, size: 14, color: AppColors.kaabaGold),
            const SizedBox(width: 6),
            Text('Today', style: AppTextStyles.small(color: AppColors.kaabaGold, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MONTH GRID
// =============================================================================

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final int direction;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.direction,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  /// Both Hijri months a Gregorian month overlaps, e.g. "Rabi' I – Rabi' II".
  String _hijriSpan() {
    final start = _hijriFor(focusedMonth);
    final end = _hijriFor(DateTime(focusedMonth.year, focusedMonth.month + 1, 0));
    if (start.month == end.month) return '${start.monthNameEnglish} ${start.year}';
    final years = start.year == end.year ? '${end.year}' : '${start.year}–${end.year}';
    return '${start.monthNameEnglish} – ${end.monthNameEnglish} $years';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ArrowButton(icon: Icons.chevron_left_rounded, onTap: () => onMonthChanged(-1)),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(focusedMonth),
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(focusedMonth),
                        style: AppTextStyles.body(weight: FontWeight.w600),
                      ),
                      Text(
                        _hijriSpan(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.tiny(color: AppColors.kaabaGold.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ),
              _ArrowButton(icon: Icons.chevron_right_rounded, onTap: () => onMonthChanged(1)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _WeekdayHeader(),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            // Swipe sideways to page through months.
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() < 250) return;
              onMonthChanged(v < 0 ? 1 : -1);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(focusedMonth);
                final dx = (incoming ? 0.12 : -0.12) * direction;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              child: KeyedSubtree(
                key: ValueKey(focusedMonth),
                child: _buildDays(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDays() {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final last = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    // Only as many weeks as the month needs, so short months don't trail an
    // empty row of next month's days.
    final weeks = ((last.difference(start).inDays + 1) / 7).ceil();

    return Column(
      children: [
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: EdgeInsets.only(bottom: w == weeks - 1 ? 0 : 4),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(child: _buildCell(DateTime(start.year, start.month, start.day + w * 7 + d))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(DateTime date) {
    final event = IslamicDayUtils.messageForDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: _DayCell(
        hijriDay: _hijriFor(date).day,
        gregorianDay: date.day,
        inMonth: date.month == focusedMonth.month,
        isToday: _sameDay(date, today),
        isSelected: _sameDay(date, selectedDate),
        isFriday: date.weekday == DateTime.friday,
        eventColor: event != null ? IslamicDayUtils.accentColor(event.type) : null,
        onTap: () => onDateSelected(date),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: PressableHaptic.none,
      pressedScale: 0.85,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 24),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Text(
              days[i],
              textAlign: TextAlign.center,
              style: AppTextStyles.tiny(
                color: i == 4 ? AppColors.kaabaGold : Colors.white.withValues(alpha: 0.45),
              ).copyWith(fontWeight: i == 4 ? FontWeight.w700 : FontWeight.w500, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

/// One day: the Hijri date large, the Gregorian date small beneath it, and a
/// dot when the day carries an occasion.
class _DayCell extends StatelessWidget {
  final int hijriDay;
  final int gregorianDay;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool isFriday;
  final Color? eventColor;
  final VoidCallback onTap;

  const _DayCell({
    required this.hijriDay,
    required this.gregorianDay,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.isFriday,
    required this.eventColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary;
    if (isToday) {
      primary = const Color(0xFF1A1405);
    } else if (!inMonth) {
      primary = Colors.white.withValues(alpha: 0.28);
    } else {
      primary = Colors.white.withValues(alpha: 0.95);
    }
    final secondary = isToday
        ? const Color(0xFF1A1405).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: inMonth ? 0.45 : 0.2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.kaabaGold
                : isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: isSelected && !isToday
                ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                : isSelected && isToday
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hijriDay',
                style: AppTextStyles.tabular(
                  AppTextStyles.body(
                    color: primary,
                    weight: isToday ? FontWeight.w700 : FontWeight.w600,
                  ).copyWith(height: 1.1, shadows: const []),
                ),
              ),
              Text(
                '$gregorianDay',
                style: AppTextStyles.tabular(
                  AppTextStyles.tiny(color: secondary)
                      .copyWith(fontSize: 10, height: 1.2, shadows: const []),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: eventColor == null
                      ? Colors.transparent
                      : isToday
                          ? const Color(0xFF1A1405)
                          : eventColor!.withValues(alpha: inMonth ? 1 : 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DAY DETAIL
// =============================================================================

class _DayDetail extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final DateTime? maghribTime;

  const _DayDetail({required this.date, required this.isToday, this.maghribTime});

  @override
  Widget build(BuildContext context) {
    final hijri = isToday
        ? HijriDate.fromDateTime(DateTime.now(), maghribTime: maghribTime)
        : _hijriFor(date);
    final event = isToday
        ? IslamicDayUtils.messageForDate(DateTime.now(), maghribTime: maghribTime)
        : IslamicDayUtils.messageForDate(date);
    final accent = event != null ? IslamicDayUtils.accentColor(event.type) : AppColors.kaabaGold;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey('${date.toIso8601String()}-$isToday'),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'TODAY' : DateFormat('EEEE').format(date).toUpperCase(),
                style: AppTextStyles.sectionLabel(color: accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${hijri.day} ${hijri.monthNameEnglish}',
                      style: AppTextStyles.h2(),
                    ),
                  ),
                  Text(
                    hijri.monthNameArabic,
                    style: AppTextStyles.arabic(color: accent, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${hijri.year} AH · ${DateFormat('d MMMM yyyy').format(date)}',
                style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)),
              ),
              if (event != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(IslamicDayUtils.iconForType(event.type), size: 18, color: accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(event.title, style: AppTextStyles.body(weight: FontWeight.w600)),
                    ),
                    Text(event.duration, style: AppTextStyles.tiny(color: accent)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  event.virtue,
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.8)),
                ),
                if (event.recommendedSunnahs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final sunnah in event.recommendedSunnahs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_rounded, size: 14, color: accent.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              sunnah,
                              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
              if (isToday && maghribTime != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.nightlight_round, size: 13, color: Colors.white.withValues(alpha: 0.45)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateTime.now().isAfter(maghribTime!)
                            ? 'The Hijri date turned at Maghrib, ${DateFormat('h:mm a').format(maghribTime!)}'
                            : 'The Hijri date turns at Maghrib, ${DateFormat('h:mm a').format(maghribTime!)}',
                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// THIS MONTH
// =============================================================================

class _MonthEvents extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _MonthEvents({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final events = IslamicDayUtils.eventsForMonth(focusedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIS MONTH',
          style: AppTextStyles.sectionLabel(color: AppColors.kaabaGold.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: AppSpacing.md),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'A quiet month. No major occasions fall in it.',
              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  if (i > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 56),
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  _EventRow(
                    entry: events[i],
                    selected: _sameDay(events[i].date, selectedDate),
                    onTap: () => onSelect(events[i].date),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final MonthEvent entry;
  final bool selected;
  final VoidCallback onTap;

  const _EventRow({required this.entry, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = IslamicDayUtils.accentColor(entry.message.type);
    final hijri = _hijriFor(entry.date);

    return Pressable(
      onTap: onTap,
      haptic: PressableHaptic.none,
      pressedScale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.3 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(IslamicDayUtils.iconForType(entry.message.type), size: 15, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(weight: selected ? FontWeight.w600 : FontWeight.w500),
                  ),
                  Text(
                    '${hijri.day} ${hijri.monthNameEnglish}',
                    style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('EEE d').format(entry.date),
              style: AppTextStyles.tabular(
                AppTextStyles.small(color: selected ? accent : Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
