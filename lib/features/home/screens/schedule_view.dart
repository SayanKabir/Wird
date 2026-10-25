import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wird2/models/prayer_status.dart'; // Ensure correct path
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../widgets/common/page_header.dart';
import '../../../core/utils/hijri_date.dart'; // Import Hijri utility
import '../../../models/prayer.dart';
import '../bloc/prayer_bloc.dart';
import '../widgets/prayer_card.dart';

class ScheduleView extends StatelessWidget {
  final PrayerLoaded state;
  const ScheduleView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // 1. Format Dates
    final gregorianStr = DateFormat('EEEE, d MMM').format(state.date); // e.g., "Saturday, 31 Jan"
    final now = DateTime.now();
    final maghribTime = state.prayerTimes[Prayer.maghrib]?.startTime;
    final hijri = HijriDate.fromDateTime(now, maghribTime: maghribTime);
    final hijriStr = '${hijri.day} ${hijri.monthNameEnglish} ${hijri.year} AH'; // e.g., "12 Sha'ban 1444 AH"

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline Column (Dot + Line)
                        Column(
                          children: [
                            // Dot
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(vertical: 22),
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
                            // Line (Connects dots)
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
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
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),

                        // Content (Prayer Card)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
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
                },
                childCount: state.enabledPrayers.length,
              ),
            ),
          ),

          // Bottom Spacer
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.navClearance(context))),
        ],
      ),
    );
  }
}