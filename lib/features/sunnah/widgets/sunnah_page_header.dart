import 'package:flutter/material.dart';

import '../../../core/constants/text_styles.dart';

class SunnahPageHeader extends StatelessWidget {
  final String heading;
  final String subheading;

  const SunnahPageHeader({
    super.key,
    required this.heading,
    required this.subheading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: AppTextStyles.tiny(
            color: Colors.white.withValues(alpha: 0.5),
          ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subheading, style: AppTextStyles.h2(color: Colors.white)),
      ],
    );
  }
}
