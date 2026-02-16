import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class SunnahOtherHeader extends StatelessWidget {
  final int count;
  final bool expandAll;
  final int activeFilterCount;
  final List<String> activeFilterTags;
  final VoidCallback onToggleExpandAll;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onRemoveTag;

  const SunnahOtherHeader({
    super.key,
    required this.count,
    required this.expandAll,
    required this.activeFilterCount,
    required this.activeFilterTags,
    required this.onToggleExpandAll,
    required this.onOpenFilters,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final isFilterActive = activeFilterCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title row ──────────────────────────
        Row(
          children: [
            // Title — NOT wrapped in Flexible/Expanded so it never clips
            Text(
              'Other Sunnahs',
              style: AppTextStyles.h3(color: Colors.white).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            _buildCountBadge(count),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),

        // ── Controls row ──────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Expand / Collapse
            _glassButton(
              icon: expandAll ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              label: expandAll ? 'Collapse All' : 'Expand All',
              onTap: onToggleExpandAll,
            ),
            const SizedBox(width: 8),
            // Filter button
            _glassButton(
              icon: Icons.tune_rounded,
              label: 'Filters',
              onTap: onOpenFilters,
              badge: isFilterActive ? activeFilterCount : null,
              accent: isFilterActive,
            ),
          ],
        ),

        // ── Active filter tags ─────────────────
        if (activeFilterTags.isNotEmpty) ...[
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuart,
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: activeFilterTags.map((tag) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onRemoveTag(tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.activeGlow.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.activeGlow.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: AppTextStyles.tiny(color: AppColors.activeGlow),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.activeGlow.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ── Small helpers ─────────────────────────────

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badge,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.activeGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: AppTextStyles.tiny(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
