import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../core/utils/hijri_date.dart';
import '../../../core/utils/islamic_day_utils.dart';

class IslamicCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;
  final PrayerPeriod prayerPeriod;

  const IslamicCalendarScreen({
    super.key,
    this.initialDate,
    this.prayerPeriod = PrayerPeriod.isha,
  });

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDate ?? DateTime.now();
    _focusedMonth = DateTime(seed.year, seed.month, 1);
    _selectedDate = DateTime(seed.year, seed.month, seed.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijriNow = HijriDate.fromGregorian(now);
    final hijriFocused = HijriDate.fromGregorian(_focusedMonth);
    final gradientColors = AppColors.getGradientForPeriod(widget.prayerPeriod);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header
              SliverToBoxAdapter(
                child: _Header(
                  hijriFocused: hijriFocused,
                  focusedMonth: _focusedMonth,
                ).animate().fadeIn(duration: 400.ms),
              ),

              // 2. Today Card
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _TodayCard(now: now, hijri: hijriNow)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                ),
              ),

              // 3. Calendar Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _CalendarSection(
                      focusedMonth: _focusedMonth,
                      selectedDate: _selectedDate,
                      today: DateTime(now.year, now.month, now.day),
                      onMonthChanged: (m) =>
                          setState(() => _focusedMonth = m),
                      onDateSelected: (d) =>
                          setState(() => _selectedDate = d),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                ),
              ),

              // 4. Special Days
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: _SpecialDaysList(focusedMonth: _focusedMonth)
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms),
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
// HEADER
// =============================================================================

class _Header extends StatelessWidget {
  final HijriDate hijriFocused;
  final DateTime focusedMonth;

  const _Header({
    required this.hijriFocused,
    required this.focusedMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ISLAMIC CALENDAR',
            style: AppTextStyles.tiny(
              color: AppColors.kaabaGold.withValues(alpha: 0.8),
            ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   hijriFocused.monthNameEnglish,
          //   style: AppTextStyles.h1(color: Colors.white),
          // ),
          // const SizedBox(height: 4),
          // Text(
          //   'Hijri ${hijriFocused.year}  •  ${DateFormat('MMMM yyyy').format(focusedMonth)}',
          //   style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.5)),
          // ),
        ],
      ),
    );
  }
}

// =============================================================================
// TODAY CARD
// =============================================================================

class _TodayCard extends StatelessWidget {
  final DateTime now;
  final HijriDate hijri;

  const _TodayCard({required this.now, required this.hijri});

  @override
  Widget build(BuildContext context) {
    final todayEvent = IslamicDayUtils.messageForDate(now);
    final hasEvent = todayEvent != null;
    final accentColor =
        hasEvent ? IslamicDayUtils.accentColor(todayEvent.type) : AppColors.kaabaGold;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY',
                  style: AppTextStyles.tiny(color: accentColor).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${hijri.day} ${hijri.monthNameEnglish}',
                  style: AppTextStyles.h2(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hijri ${hijri.year}',
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
                ),
                if (hasEvent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IslamicDayUtils.iconForType(todayEvent.type), size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          todayEvent.title,
                          style: AppTextStyles.tiny(color: accentColor).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('EEEE').format(now),
                style: AppTextStyles.small(
                  color: Colors.white.withValues(alpha: 0.7),
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM yyyy').format(now),
                style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CALENDAR SECTION
// =============================================================================

class _CalendarSection extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarSection({
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final monthDates = _monthGridDates(focusedMonth);
    final hijriDates = <int, HijriDate>{};
    final events = <int, IslamicDayMessage?>{};

    for (var i = 0; i < monthDates.length; i++) {
      hijriDates[i] = HijriDate.fromGregorian(monthDates[i]);
      events[i] = IslamicDayUtils.messageForDate(monthDates[i]);
    }

    final hijriMid = HijriDate.fromGregorian(
      DateTime(focusedMonth.year, focusedMonth.month, 15),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _MonthNavigator(
            focusedMonth: focusedMonth,
            hijriMonthName: hijriMid.monthNameEnglish,
            onChanged: onMonthChanged,
          ),
          const SizedBox(height: 20),
          const _WeekdayHeader(),
          const SizedBox(height: 12),
          _buildGrid(monthDates, hijriDates, events),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<DateTime> monthDates,
    Map<int, HijriDate> hijriDates,
    Map<int, IslamicDayMessage?> events,
  ) {
    final rows = <Widget>[];
    for (var row = 0; row < 6; row++) {
      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final index = row * 7 + col;
        final date = monthDates[index];
        final hijri = hijriDates[index]!;
        final event = events[index];
        final isCurrentMonth = date.month == focusedMonth.month;
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;

        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onDateSelected(date);
              },
              child: _DayCell(
                gregorianDay: date.day,
                hijriDay: hijri.day,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                hasEvent: event != null,
                eventColor: event != null
                    ? IslamicDayUtils.accentColor(event.type)
                    : null,
              ),
            ),
          ),
        );
        if (col < 6) cells.add(const SizedBox(width: 4));
      }
      rows.add(Row(children: cells));
      if (row < 5) rows.add(const SizedBox(height: 4));
    }
    return Column(children: rows);
  }

  List<DateTime> _monthGridDates(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final startWeekday = firstOfMonth.weekday;
    final startDate = firstOfMonth.subtract(Duration(days: startWeekday - 1));
    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }
}

// =============================================================================
// MONTH NAVIGATOR
// =============================================================================

class _MonthNavigator extends StatelessWidget {
  final DateTime focusedMonth;
  final String hijriMonthName;
  final ValueChanged<DateTime> onChanged;

  const _MonthNavigator({
    required this.focusedMonth,
    required this.hijriMonthName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(DateTime(focusedMonth.year, focusedMonth.month - 1, 1));
          },
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Column(
              key: ValueKey(focusedMonth),
              children: [
                Text(hijriMonthName, style: AppTextStyles.h3(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM yyyy').format(focusedMonth),
                  style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(DateTime(focusedMonth.year, focusedMonth.month + 1, 1));
          },
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

// =============================================================================
// WEEKDAY HEADER
// =============================================================================

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: days.asMap().entries.map((entry) {
        final isFriday = entry.key == 4;
        return Expanded(
          child: Text(
            entry.value,
            textAlign: TextAlign.center,
            style: AppTextStyles.tiny(
              color: isFriday
                  ? AppColors.activeGlow
                  : Colors.white.withValues(alpha: 0.35),
            ).copyWith(
              fontWeight: isFriday ? FontWeight.bold : FontWeight.w500,
              letterSpacing: isFriday ? 1 : 0,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// DAY CELL — Vertical dual-date layout: Hijri (prominent) + Gregorian (dimmed)
// =============================================================================

class _DayCell extends StatelessWidget {
  final int gregorianDay;
  final int hijriDay;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final Color? eventColor;

  const _DayCell({
    required this.gregorianDay,
    required this.hijriDay,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
    this.eventColor,
  });

  @override
  Widget build(BuildContext context) {
    final contentOpacity = isCurrentMonth ? 1.0 : 0.25;

    Color bgColor = Colors.transparent;
    if (isSelected && !isToday) {
      bgColor = Colors.white.withValues(alpha: 0.12);
    } else if (isToday) {
      bgColor = AppColors.kaabaGold.withValues(alpha: 0.12);
    }

    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: AppColors.kaabaGold.withValues(alpha: 0.6), width: 1.5)
              : isSelected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.5))
                  : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dates column — always centered
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hijri day — prominent
                  Opacity(
                    opacity: contentOpacity,
                    child: Text(
                      '$hijriDay',
                      style: TextStyle(
                        color: isToday
                            ? AppColors.kaabaGold
                            : Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Gregorian day — dimmed below
                  Opacity(
                    opacity: contentOpacity * 0.55,
                    child: Text(
                      '$gregorianDay',
                      style: TextStyle(
                        color: isToday
                            ? AppColors.kaabaGold.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Event dot — always positioned at bottom, invisible when no event
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasEvent
                      ? (eventColor ?? Colors.white)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SPECIAL DAYS LIST — Uses eventsForMonth for deduplication
// =============================================================================

class _SpecialDaysList extends StatefulWidget {
  final DateTime focusedMonth;
  const _SpecialDaysList({required this.focusedMonth});

  @override
  State<_SpecialDaysList> createState() => _SpecialDaysListState();
}

class _SpecialDaysListState extends State<_SpecialDaysList> {
  final Set<int> _expandedIndices = {};

  @override
  void didUpdateWidget(covariant _SpecialDaysList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth != widget.focusedMonth) {
      _expandedIndices.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = IslamicDayUtils.eventsForMonth(widget.focusedMonth);

    if (events.isEmpty) {
      return _EmptyEventState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIS MONTH\'S EVENTS',
          style: AppTextStyles.tiny(
            color: AppColors.kaabaGold.withValues(alpha: 0.7),
          ).copyWith(letterSpacing: 3, fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final isExpanded = _expandedIndices.contains(index);
            return _EventCard(
              entry: events[index],
              isExpanded: isExpanded,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() {
                  isExpanded
                      ? _expandedIndices.remove(index)
                      : _expandedIndices.add(index);
                });
              },
            )
                .animate()
                .fadeIn(delay: (index * 80).ms, duration: 400.ms)
                .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
          },
        ),
      ],
    );
  }
}

// =============================================================================
// EVENT CARD — Expandable: collapsed shows title + duration, tap to reveal
// virtue and sunnahs
// =============================================================================

class _EventCard extends StatelessWidget {
  final MonthEvent entry;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _EventCard({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = IslamicDayUtils.accentColor(entry.message.type);
    final icon = IslamicDayUtils.iconForType(entry.message.type);
    final hijri = HijriDate.fromGregorian(entry.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isExpanded
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded
                  ? accent.withValues(alpha: 0.35)
                  : accent.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Collapsed header (always visible) ---
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Icon(icon, size: 22, color: accent),
                  ),
                  const SizedBox(width: 14),
                  // Title + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.message.title,
                          style: AppTextStyles.body(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              DateFormat('EEE, d MMM').format(entry.date),
                              style: AppTextStyles.tiny(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '${hijri.day} ${hijri.monthNameEnglish}',
                              style: AppTextStyles.tiny(color: AppColors.kaabaGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Duration pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      entry.message.duration,
                      style: AppTextStyles.tiny(color: accent)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                    ),
                  ),
                ],
              ),

              // --- Expandable body ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? _buildExpandedBody(accent)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedBody(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: 16),

        // Virtue section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 15, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIRTUE',
                    style: AppTextStyles.tiny(
                      color: Colors.white.withValues(alpha: 0.4),
                    ).copyWith(letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.message.virtue,
                    style: AppTextStyles.small(
                      color: Colors.white.withValues(alpha: 0.85),
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Sunnahs section
        if (entry.message.recommendedSunnahs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'RECOMMENDED SUNNAHS',
            style: AppTextStyles.tiny(
              color: Colors.white.withValues(alpha: 0.4),
            ).copyWith(letterSpacing: 1, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...entry.message.recommendedSunnahs.map((sunnah) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sunnah,
                        style: AppTextStyles.small(
                          color: Colors.white.withValues(alpha: 0.7),
                        ).copyWith(height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptyEventState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.nightlight_round_outlined,
              color: Colors.white.withValues(alpha: 0.15),
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              'A month of quiet reflection',
              style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 6),
            Text(
              'No major occasions this month',
              style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.25)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
