import 'package:flutter/material.dart';

import '../../core/constants/durations.dart';
import '../../core/services/device_profile.dart';

/// The one way screens are pushed in Wird: the new screen fades in while
/// rising a short way, and on the way back it fades and sinks a little
/// quicker. The screen underneath stays still, so only one thing moves.
///
/// With system animations off, it's a plain cross-fade.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required super.builder, super.settings, super.fullscreenDialog});

  @override
  Duration get transitionDuration => AppDurations.route;

  @override
  Duration get reverseTransitionDuration => AppDurations.routeReverse;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasized,
      // Played backwards on pop, the flipped curve starts fast, so the
      // leaving screen gets out of the way immediately.
      reverseCurve: AppCurves.emphasized.flipped,
    );
    if (motionStill()) return FadeTransition(opacity: curved, child: child);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
