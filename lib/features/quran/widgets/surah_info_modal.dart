import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/repositories/surah_info_local_repository.dart';

class SurahInfoModal extends StatelessWidget {
  final SurahInfoData info;

  const SurahInfoModal({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Background Glow
          // Positioned(
          //   top: -100,
          //   left: -50,
          //   right: -50,
          //   height: 300,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       gradient: RadialGradient(
          //         colors: [
          //           AppColors.spiritualGold.withValues(alpha: 0.15),
          //           Colors.transparent,
          //         ],
          //         radius: 0.8,
          //       ),
          //     ),
          //   ),
          // ),
          
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.spiritualGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.spiritualGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        info.title,
                        style: AppTextStyles.h2(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Badge(
                            icon: info.revelation.toLowerCase() == 'mecca' ? '🕋' : '🕌',
                            text: info.revelation,
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            icon: '⏳',
                            text: info.period,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Content Section
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Section(
                          title: 'Background & Context',
                          icon: Icons.history_edu_rounded,
                          content: info.background,
                        ),
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Major Themes',
                          icon: Icons.format_list_bulleted_rounded,
                          content: info.themes,
                        ),
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Virtues',
                          icon: Icons.star_rounded,
                          content: info.virtues,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final String text;

  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _Section({required this.title, required this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.spiritualGold, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.h3(color: AppColors.spiritualGold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            content,
            style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.85)).copyWith(
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
