import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../widgets/common/glass_container.dart';

class SunnahGamificationStrip extends StatelessWidget {
  final int level;
  final int totalPoints;
  final double levelProgress;
  final int streak;
  final int practicedTodayCount;
  final int practicedUniqueCount;
  final int totalSunnahCount;
  final List<String> badges;

  const SunnahGamificationStrip({
    super.key,
    required this.level,
    required this.totalPoints,
    required this.levelProgress,
    required this.streak,
    required this.practicedTodayCount,
    required this.practicedUniqueCount,
    required this.totalSunnahCount,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.1,
      blur: 10,
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('Lvl $level', 'Level'),
              const SizedBox(width: 12),
              _stat('$totalPoints', 'Points'),
              const SizedBox(width: 12),
              _stat('$streak', 'Streak'),
              const Spacer(),
              Text(
                '$practicedTodayCount today',
                style: AppTextStyles.small(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.activeGlow),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$practicedUniqueCount / $totalSunnahCount revived',
                style: AppTextStyles.tiny(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              if (badges.isNotEmpty)
                Text(
                  badges.map((b) => '🏅 $b').join('  '),
                  style: AppTextStyles.tiny(
                    color: AppColors.spiritualGold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.tiny(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
