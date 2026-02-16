import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/sunnah.dart';
import '../../../widgets/common/glass_container.dart';

class SunnahWeeklyCard extends StatelessWidget {
  final Sunnah sunnah;
  final String weekLabel;
  final bool isDhikrLinked;
  final IconData categoryIcon;
  final String difficultyLabel;
  final String frequencyLabel;
  final bool isPracticedToday;
  final VoidCallback onPracticeTap;
  final VoidCallback onReadDetailsTap;
  final VoidCallback onOpenTasbihTap;
  final VoidCallback onSkipTap;

  const SunnahWeeklyCard({
    super.key,
    required this.sunnah,
    required this.weekLabel,
    required this.isDhikrLinked,
    required this.categoryIcon,
    required this.difficultyLabel,
    required this.frequencyLabel,
    required this.isPracticedToday,
    required this.onPracticeTap,
    required this.onReadDetailsTap,
    required this.onOpenTasbihTap,
    required this.onSkipTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.06,
      borderOpacity: 0.12,
      blur: 12,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.spiritualGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.spiritualGold.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'SUNNAH OF THE WEEK',
                  style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSkipTap();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.shuffle_rounded, color: Colors.white.withValues(alpha: 0.6), size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Icon(categoryIcon, color: Colors.white.withValues(alpha: 0.8), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weekLabel,
            style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 12),
          Text(sunnah.title, style: AppTextStyles.h3(color: Colors.white)),
          if (sunnah.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sunnah.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 12),
          // Meta pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(difficultyLabel, AppColors.activeGlow),
              _pill(frequencyLabel, Colors.white.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons row
          Row(
            children: [
              _actionBtn(
                label: 'Details',
                icon: Icons.info_outline_rounded,
                onTap: onReadDetailsTap,
                filled: false,
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: isPracticedToday ? 'Done' : 'I\'m Practicing this',
                icon: isPracticedToday
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                onTap: onPracticeTap,
                filled: !isPracticedToday,
                color: isPracticedToday ? const Color(0xFF73D38A) : AppColors.activeGlow,
              ),
              if (isDhikrLinked) ...[
                const SizedBox(width: 8),
                _actionBtn(
                  label: 'Tasbih',
                  icon: Icons.touch_app_rounded,
                  onTap: onOpenTasbihTap,
                  filled: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.tiny(color: color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: filled ? c.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(
                color: filled
                    ? c.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: filled ? c : Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: filled ? c : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
