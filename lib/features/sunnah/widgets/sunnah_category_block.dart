import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/sunnah.dart';
import '../../../widgets/common/glass_container.dart';

class SunnahCategoryBlock extends StatelessWidget {
  final String category;
  final List<Sunnah> sunnahs;
  final bool isExpanded;
  final String typeSummary;
  final IconData icon;
  final VoidCallback onToggle;
  final Widget Function(Sunnah sunnah) tileBuilder;

  const SunnahCategoryBlock({
    super.key,
    required this.category,
    required this.sunnahs,
    required this.isExpanded,
    required this.typeSummary,
    required this.icon,
    required this.onToggle,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category header ─────────────────────
        Container(
          decoration: category == 'Dhikr & Azkar'
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.spiritualGold.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: GlassContainer(
            opacity: category == 'Dhikr & Azkar' ? 0.20 : (isExpanded ? 0.10 : 0.06),
            borderOpacity: category == 'Dhikr & Azkar' ? 0.5 : (isExpanded ? 0.14 : 0.08),
            color: category == 'Dhikr & Azkar' ? AppColors.spiritualGold : null,
            blur: 0,
            borderRadius: 16,
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Row(
              children: [
                // Accent dot
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.activeGlow.withValues(alpha: 0.7)
                        : (category == 'Dhikr & Azkar' 
                            ? AppColors.spiritualGold.withValues(alpha: 0.9) 
                            : Colors.white.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  icon, 
                  color: category == 'Dhikr & Azkar' 
                      ? AppColors.spiritualGold.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.85), 
                  size: 17,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: AppTextStyles.bodyMedium(
                        color: category == 'Dhikr & Azkar' 
                            ? AppColors.spiritualGold 
                            : Colors.white,
                      ).copyWith(
                        fontWeight: category == 'Dhikr & Azkar' ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny(
                        color: category == 'Dhikr & Azkar'
                            ? AppColors.spiritualGold.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: category == 'Dhikr & Azkar'
                      ? AppColors.spiritualGold.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sunnahs.length}',
                  style: AppTextStyles.tiny(
                    color: category == 'Dhikr & Azkar'
                        ? AppColors.spiritualGold.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: category == 'Dhikr & Azkar'
                      ? AppColors.spiritualGold.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.45),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        ),
        // ── Expanded tiles ──────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: sunnahs.map((s) => tileBuilder(s)).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
