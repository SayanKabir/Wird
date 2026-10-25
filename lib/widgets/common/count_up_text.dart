import 'package:flutter/material.dart';

import '../../core/constants/durations.dart';
import '../../core/services/device_profile.dart';

/// Shows [value] (e.g. "42", "45%"), counting the leading number up from 0
/// when [animate] is true. Anything that doesn't start with a whole number
/// ("1.3k", "--") is shown as is. Digits are tabular so the width holds
/// steady while counting.
class CountUpText extends StatelessWidget {
  final String value;
  final TextStyle style;
  final bool animate;

  const CountUpText(this.value, {super.key, required this.style, this.animate = true});

  static final _leading = RegExp(r'^(\d+)(.*)$');

  @override
  Widget build(BuildContext context) {
    final steady = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final match = _leading.firstMatch(value);
    if (!animate || match == null || motionStill() || value.contains('.')) {
      return Text(value, style: steady);
    }
    final target = int.parse(match.group(1)!);
    final suffix = match.group(2)!;
    if (target == 0) return Text(value, style: steady);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: AppCurves.emphasized,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: steady),
    );
  }
}
