import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wird2/models/prayer_status.dart'; // Ensure correct path
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/device_profile.dart';
import '../../../widgets/common/page_header.dart';
import '../../../core/utils/hijri_date.dart'; // Import Hijri utility
import '../../../models/prayer.dart';
import '../bloc/prayer_bloc.dart';
import '../widgets/prayer_card.dart';

class ScheduleView extends StatefulWidget {
  final PrayerLoaded state;
  const ScheduleView({super.key, required this.state});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  /// How far the list is pulled past its top (positive) or bottom
  /// (negative) edge. The timeline stretches by it like a rubber band, and
  /// springs shut with the bounce as it returns to zero.
  final ValueNotifier<double> _overscroll = ValueNotifier(0);

  /// How much each gap between rows widens per pixel of overscroll.
  static const double _stretchPerGap = 0.12;

  @override
  void dispose() {
    _overscroll.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (n.depth != 0 || m.axis != Axis.vertical) return false;
    _overscroll.value = m.pixels < m.minScrollExtent
        ? m.minScrollExtent - m.pixels
        : m.pixels > m.maxScrollExtent
            ? m.maxScrollExtent - m.pixels
            : 0;
    return false;
  }

  /// Extra offset for row [index] of [count]. Pulled down, the rows fan out
  /// from the header so the lowest moves most; pulled up, they fan out from
  /// the bottom so the highest moves most. Either way every gap widens by
  /// the same amount, which [_TimelineLine] bridges.
  double _rowShift(int index, int count, double overscroll) {
    final gaps = overscroll > 0 ? index + 1 : count - index;
    return overscroll * _stretchPerGap * gaps;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final still = motionStill();

    // 1. Format Dates
    final gregorianStr = DateFormat('EEEE, d MMM').format(state.date); // e.g., "Saturday, 31 Jan"
    final now = DateTime.now();
    final maghribTime = state.prayerTimes[Prayer.maghrib]?.startTime;
    final hijri = HijriDate.fromDateTime(now, maghribTime: maghribTime);
    final hijriStr = '${hijri.day} ${hijri.monthNameEnglish} ${hijri.year} AH'; // e.g., "12 Sha'ban 1444 AH"

    return SafeArea(
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: still ? null : _onScroll,
        child: CustomScrollView(
        // Always scrollable: on most phones the day fits on one screen, and
        // without this the list ignores drags, so it can't bounce or stretch.
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header: same PageHeader as every other tab, with the Hijri date
          // as the overline and today's date as the title.
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.header(context),
              child: PageHeader(
                overline: hijriStr.toUpperCase(),
                title: gregorianStr,
              ),
            ),
          ),

          // 3. Timeline List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter(context)),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final prayer = state.enabledPrayers[index];
                  final timeData = state.prayerTimes[prayer];
                  final entry = state.statuses[prayer];
                  final isLast = index == state.enabledPrayers.length - 1;
                  final isActive = prayer == state.currentPrayer;

                  final row = IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline Column (Dot + Line)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const SizedBox(width: 12),
                            // Dot
                            Container(
                              width: 12,
                              height: 12,
                              // Centred on the card's 40px icon (14px padding + 20).
                              margin: const EdgeInsets.only(top: 28, bottom: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.activeGlow
                                    : (entry?.status.isCompleted ?? false)
                                    ? AppColors.statusOnTime
                                    : Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: isActive
                                    ? Border.all(color: AppColors.activeGlow.withOpacity(0.5), width: 3)
                                    : null,
                                boxShadow: isActive ? [
                                  BoxShadow(
                                    color: AppColors.activeGlow.withOpacity(0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ] : null,
                              ),
                            ),
                            // Line (Connects dots). It reaches past the row's
                            // bottom by however far the stretch has opened
                            // the gap, so it stays joined to the next dot.
                            if (!isLast)
                              ValueListenableBuilder<double>(
                                valueListenable: _overscroll,
                                builder: (context, overscroll, _) => Positioned(
                                  top: 46,
                                  bottom: -overscroll.abs() * _stretchPerGap,
                                  left: 5,
                                  width: 2,
                                  child: const _TimelineLine(),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),

                        // Content (Prayer Card)
                        Expanded(
                          child: Padding(
                            // The card's own 12px margin is the gap between rows.
                            padding: EdgeInsets.zero,
                            child: Builder(
                              builder: (context) {
                                final now = DateTime.now();
                                final hasStarted = timeData == null || prayer.isSunnah || now.isAfter(timeData.startTime);
                                final isCompleted = entry?.status.isCompleted ?? false;
                                
                                return PrayerCard(
                                  date: state.date,
                                  prayer: prayer,
                                  timeData: timeData,
                                  entry: entry,
                                  isActive: isActive,
                                  // Only allow marking complete if prayer has started and not yet completed
                                  onMarkComplete: hasStarted && !isCompleted ? () {
                                    context.read<PrayerBloc>().add(MarkPrayerComplete(
                                      prayer: prayer,
                                      isOnTime: timeData != null && now.isBefore(timeData.endTime),
                                    ));
                                  } : null,
                                  // Only allow toggling jamaah if prayer is completed
                                  onToggleJamaah: isCompleted ? () {
                                    context.read<PrayerBloc>().add(ToggleJamaah(prayer: prayer));
                                  } : null,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (still) return row;
                  return ValueListenableBuilder<double>(
                    valueListenable: _overscroll,
                    builder: (context, overscroll, child) => Transform.translate(
                      offset: Offset(0, _rowShift(index, state.enabledPrayers.length, overscroll)),
                      child: child,
                    ),
                    child: row,
                  );
                },
                childCount: state.enabledPrayers.length,
              ),
            ),
          ),

          // Bottom Spacer
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.navClearance(context))),
        ],
        ),
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
    );
  }
}