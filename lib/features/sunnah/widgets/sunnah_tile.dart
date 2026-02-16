import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/sunnah.dart';
import '../../../widgets/common/glass_container.dart';

class SunnahTile extends StatelessWidget {
  final Sunnah sunnah;
  final String subtitle;
  final bool isDhikrLinked;
  final bool isPracticedToday;
  final Color difficultyColor;
  final String difficultyLabel;
  final String frequencyLabel;
  final String shortReference;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const SunnahTile({
    super.key,
    required this.sunnah,
    required this.subtitle,
    required this.isDhikrLinked,
    required this.isPracticedToday,
    required this.difficultyColor,
    required this.difficultyLabel,
    required this.frequencyLabel,
    required this.shortReference,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        opacity: isPracticedToday ? 0.06 : 0.03,
        borderOpacity: isPracticedToday ? 0.12 : 0.08,
        blur: 0,
        borderRadius: 16,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon with practiced accent
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                categoryIcon,
                color: isPracticedToday
                    ? const Color(0xFF73D38A).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.45),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sunnah.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                            color: Colors.white.withValues(alpha: 0.95),
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isPracticedToday) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: const Color(0xFF73D38A),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Pills row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _pill(difficultyLabel, difficultyColor),
                      _pill(frequencyLabel, Colors.white.withValues(alpha: 0.55)),
                      if (shortReference.isNotEmpty)
                        _pill(shortReference, Colors.white.withValues(alpha: 0.4)),
                      if (isDhikrLinked)
                        _pill('Tasbih', AppColors.activeGlow),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron hint
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.tiny(color: color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
