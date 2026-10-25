import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/constants/colors.dart';
import '../../../widgets/common/pressable.dart';
import '../../../core/constants/durations.dart';

// ─────────────────── Folding scroll ───────────────────

/// A scroll view whose text tilts back and fades as it nears the top or
/// bottom edge, like rows on an iOS picker wheel, instead of being sliced off
/// by the clip. It still rubber-bands at the ends.
///
/// The fold only applies on a side that has more content beyond it, so text
/// at rest (scrolled to the top, or too short to scroll) sits flat.
///
/// The fold costs an offscreen layer per word, so with lighter visuals the
/// edges with more content get a single gradient mask instead: text still
/// fades rather than ending in a hard cut, and the scroll keeps its bounce
/// (which only stops when the system asks for no animation).
///
/// Wrap text in [FoldText] (or single widgets in [Fold]) to take part: each
/// word folds on its own, so a long paragraph curls away line by line.
class FoldingScrollView extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;

  const FoldingScrollView({super.key, required this.child, this.padding = EdgeInsets.zero});

  @override
  State<FoldingScrollView> createState() => _FoldingScrollViewState();
}

class _FoldingScrollViewState extends State<FoldingScrollView> {
  static const double _fade = 36;

  final ScrollController _controller = ScrollController();
  bool _moreAbove = false;
  bool _moreBelow = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics m) {
    final above = m.pixels > 0.5;
    final below = m.pixels < m.maxScrollExtent - 0.5;
    if (above != _moreAbove || below != _moreBelow) {
      setState(() {
        _moreAbove = above;
        _moreBelow = below;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = motionMode();
    final scroll = SingleChildScrollView(
      controller: _controller,
      // The bounce is cheap, so it stays in lite mode.
      physics: mode == MotionMode.still ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      padding: widget.padding,
      child: widget.child,
    );
    if (mode == MotionMode.full) return _FoldScope(controller: _controller, child: scroll);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: _FoldScope(
          controller: null,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final top = _moreAbove ? _fade / rect.height : 0.0;
              final bottom = _moreBelow ? 1 - _fade / rect.height : 1.0;
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _moreAbove ? Colors.transparent : Colors.black,
                  Colors.black,
                  Colors.black,
                  _moreBelow ? Colors.transparent : Colors.black,
                ],
                stops: [0, top, bottom, 1],
              ).createShader(rect);
            },
            child: scroll,
          ),
        ),
      ),
    );
  }
}

class _FoldScope extends InheritedWidget {
  final ScrollController? controller;

  const _FoldScope({required this.controller, required super.child});

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FoldScope>()?.controller;

  @override
  bool updateShouldNotify(_FoldScope old) => old.controller != controller;
}

/// Text laid out word by word so each word can fold independently. Marks that
/// have no letters of their own (Quranic pause signs) stay glued to the word
/// before them so they never render on their own.
class FoldText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextDirection direction;
  final double lineGap;

  const FoldText(
    this.text, {
    super.key,
    required this.style,
    this.direction = TextDirection.ltr,
    this.lineGap = 0,
  });

  static final _hasLetter = RegExp(r'[A-Za-z0-9ء-يٮ-ۓۺ-ۿ]');

  List<String> _words(String line) {
    final out = <String>[];
    for (final token in line.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (out.isNotEmpty && !_hasLetter.hasMatch(token)) {
        out[out.length - 1] = '${out.last} $token';
      } else {
        out.add(token);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final space = (style.fontSize ?? 14) * 0.28;
    final lines = text.split('\n');
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: EdgeInsets.only(bottom: line == lines.last ? 0 : lineGap),
            child: Wrap(
              alignment: WrapAlignment.center,
              textDirection: direction,
              spacing: space,
              children: [
                for (final w in _words(line))
                  Fold(child: Text(w, style: style, textDirection: direction)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Folds its child back and fades it as it nears an edge of the enclosing
/// [FoldingScrollView]. Outside one it does nothing.
class Fold extends SingleChildRenderObjectWidget {
  const Fold({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderFold(_FoldScope.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderFold renderObject) {
    renderObject.controller = _FoldScope.of(context);
  }
}

class RenderFold extends RenderProxyBox {
  RenderFold(this.controller);

  ScrollController? controller;

  /// Height of the band at each edge where text folds away.
  static const double _band = 64;

  /// How far back a word tilts at the very edge, in radians.
  static const double _maxTilt = 1.0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    final ctl = controller;
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (ctl == null || !ctl.hasClients || !ctl.position.hasContentDimensions || viewport is! RenderBox) {
      context.paintChild(c, offset);
      return;
    }

    final position = ctl.position;
    final viewportHeight = (viewport as RenderBox).size.height;
    final center = MatrixUtils.transformPoint(getTransformTo(viewport), size.center(Offset.zero)).dy;

    // A band only exists where there's more to scroll to on that side, and it
    // grows in with the scroll so nothing jumps when scrolling starts.
    final topBand = position.pixels.clamp(0.0, _band);
    final bottomBand = (position.maxScrollExtent - position.pixels).clamp(0.0, _band);

    double t = 0;
    double side = 0;
    if (topBand > 0 && center < topBand) {
      t = (topBand - center) / topBand;
      side = 1;
    } else if (bottomBand > 0 && center > viewportHeight - bottomBand) {
      t = (center - (viewportHeight - bottomBand)) / bottomBand;
      side = -1;
    }
    t = Curves.easeIn.transform(t.clamp(0.0, 1.0));

    if (t <= 0.001) {
      context.paintChild(c, offset);
      return;
    }

    // Tilt around the word's own centre, in perspective, and pull it in a
    // touch so the fold reads as curving away from you.
    final pivot = size.center(Offset.zero);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
      ..rotateX(side * _maxTilt * t)
      ..scaleByDouble(1 - 0.12 * t, 1 - 0.12 * t, 1, 1)
      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
    final alpha = ((1 - t) * 255).round().clamp(0, 255);

    context.pushOpacity(offset, alpha, (context, offset) {
      context.pushTransform(needsCompositing, offset, transform, (context, offset) => context.paintChild(c, offset));
    });
  }
}

// ─────────────────── Tap ripple ───────────────────

/// A counting area that answers each touch with a soft ring spreading out
/// from where the finger landed, plus a slight press-in of its content.
/// Counts on touch-down so rapid tapping stays responsive.
class RippleTapArea extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  const RippleTapArea({super.key, required this.onTap, required this.child, required this.semanticLabel});

  @override
  State<RippleTapArea> createState() => _RippleTapAreaState();
}

class _Ripple {
  final Offset origin;
  final AnimationController controller;

  _Ripple(this.origin, this.controller);
}

class _RippleTapAreaState extends State<RippleTapArea> with TickerProviderStateMixin {
  static const _maxRipples = 6;
  final List<_Ripple> _ripples = [];
  bool _pressed = false;

  @override
  void dispose() {
    for (final r in _ripples) {
      r.controller.dispose();
    }
    super.dispose();
  }

  void _down(TapDownDetails d) {
    widget.onTap();
    setState(() => _pressed = true);
    if (motionStill()) return;

    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    final ripple = _Ripple(d.localPosition, controller);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _ripples.remove(ripple));
        controller.dispose();
      }
    });
    setState(() {
      _ripples.add(ripple);
      if (_ripples.length > _maxRipples) {
        _ripples.removeAt(0).controller.dispose();
      }
    });
    controller.forward();
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: _pressed && !motionStill() ? 0.975 : 1,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: widget.child,
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([for (final r in _ripples) r.controller]),
                builder: (context, _) => CustomPaint(painter: _RipplePainter(_ripples)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;

  _RipplePainter(List<_Ripple> ripples) : ripples = List.of(ripples);

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in ripples) {
      final v = Curves.easeOutCubic.transform(r.controller.value);
      final fade = 1 - Curves.easeIn.transform(r.controller.value);
      final radius = 18 + 72 * v;
      canvas.drawCircle(
        r.origin,
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.10 * fade),
      );
      canvas.drawCircle(
        r.origin,
        radius,
        Paint()
          ..color = AppColors.spiritualGold.withValues(alpha: 0.45 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1 - v) + 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => true;
}

/// Ease a number in from below when it changes, like a counter ticking over.
class TickingNumber extends StatelessWidget {
  final int value;
  final TextStyle style;

  const TickingNumber({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    if (motionStill()) return Text('$value', style: style);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: AppCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(value);
        final slide = Tween<Offset>(
          begin: Offset(0, incoming ? 0.35 : -0.35),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(opacity: animation, child: SlideTransition(position: slide, child: child));
      },
      child: Text('$value', key: ValueKey(value), style: style),
    );
  }
}
