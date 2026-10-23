import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/pressable.dart';
import '../bloc/tasbih_bloc.dart';
import '../widgets/dhikr_widgets.dart';

/// A guided session: each step is said its own number of times, then the
/// next one comes up. The position is saved as you go, so leaving and coming
/// back within a couple of hours picks up where you were.
class SessionScreen extends StatefulWidget {
  final String sessionId;

  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  static const _advancePause = Duration(milliseconds: 380);

  final _store = DhikrSessionStore();
  late final DhikrSession? _session = DhikrCatalog.session(widget.sessionId);

  int _step = 0;
  int _count = 0;
  bool _finished = false;
  bool _resumed = false;
  bool _pressed = false;

  /// Set while a finished step holds for a moment before the next appears;
  /// taps in that window are ignored so a quick extra tap doesn't spill over.
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
    final session = _session;
    final resume = session == null ? null : _store.resumePoint(widget.sessionId);
    if (session != null && resume != null && resume.$1 < session.steps.length) {
      _step = resume.$1;
      _count = resume.$2.clamp(0, session.steps[resume.$1].count - 1);
      _resumed = true;
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  List<SessionStep> get _steps => _session!.steps;

  void _tally(SessionStep step, int delta) {
    final id = step.counterId;
    if (id != null) context.read<TasbihBloc>().add(CounterTallied(id, delta));
  }

  void _tap() {
    if (_finished || _advance != null) return;
    final step = _steps[_step];
    final next = _count + 1;
    _tally(step, 1);
    setState(() {
      _count = next;
      _resumed = false;
    });

    if (next < step.count) {
      HapticService().light();
      _store.savePosition(widget.sessionId, _step, _count);
      return;
    }

    final last = _step == _steps.length - 1;
    last ? HapticService().heavy() : HapticService().medium();
    // Save the outcome now, in case the screen is left during the pause.
    last ? _store.markDone(widget.sessionId) : _store.savePosition(widget.sessionId, _step + 1, 0);
    _advance = Timer(_advancePause, () {
      if (!mounted) return;
      _advance = null;
      last ? _finish() : _goTo(_step + 1);
    });
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _count = 0;
      _resumed = false;
    });
    _store.savePosition(widget.sessionId, _step, 0);
  }

  void _finish() {
    setState(() => _finished = true);
    _store.markDone(widget.sessionId);
  }

  void _undo() {
    if (_finished) return;
    _resumed = false;
    var undoingFinish = false;
    if (_advance != null) {
      // Taking back the tap that finished a step keeps you on it.
      _advance!.cancel();
      _advance = null;
      undoingFinish = _step == _steps.length - 1;
    }
    if (_count > 0) {
      _tally(_steps[_step], -1);
      setState(() => _count--);
      _store.savePosition(widget.sessionId, _step, _count, done: undoingFinish ? false : null);
    } else if (_step > 0) {
      final previous = _steps[_step - 1];
      _tally(previous, -1);
      setState(() {
        _step--;
        _count = previous.count - 1;
      });
      _store.savePosition(widget.sessionId, _step, _count);
    }
  }

  void _skip() {
    if (_finished) return;
    _advance?.cancel();
    _advance = null;
    _step == _steps.length - 1 ? _finish() : _goTo(_step + 1);
  }

  void _restart() {
    setState(() {
      _finished = false;
      _step = 0;
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return DhikrBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: session == null
              ? _unknown(context)
              : _finished
                  ? _buildFinished(context, session)
                  : _buildStep(context, session),
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) => DhikrIconButton(
        icon: Icons.close_rounded,
        tooltip: 'Close',
        onTap: () => Navigator.of(context).maybePop(),
      );

  Widget _buildStep(BuildContext context, DhikrSession session) {
    final step = session.steps[_step];
    final stepDone = _count >= step.count;

    return Column(
      children: [
        DhikrHeader(
          leading: _closeButton(context),
          title: session.name,
          subtitle: 'Step ${_step + 1} of ${session.steps.length}',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
          child: _StepBar(total: session.steps.length, current: _step, currentDone: stepDone),
        ),
        Text(
          '${step.label.toUpperCase()}${step.count > 1 ? '  ·  ${step.count}×' : ''}',
          style: AppTextStyles.tiny(color: AppColors.spiritualGold.withValues(alpha: 0.85))
              .copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: DhikrTextCard(
              key: ValueKey(_step),
              arabic: step.arabic,
              transliteration: step.transliteration,
              translation: step.translation,
              virtue: step.virtue,
              reference: step.reference,
              quranic: step.quranic,
            ),
          ),
        ),
        // Counting area: a fixed band below the text.
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.26).clamp(170.0, 230.0),
          child: Semantics(
            button: true,
            label: '${step.label}, $_count of ${step.count}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                setState(() => _pressed = true);
                _tap();
              },
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.97 : 1,
                duration: const Duration(milliseconds: 90),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    step.count <= 7
                        ? _Beads(total: step.count, done: _count)
                        : DhikrRing(
                            progress: _count / step.count,
                            size: 128,
                            child: Text(
                              '$_count',
                              style: AppTextStyles.h1(color: stepDone ? AppColors.spiritualGold : Colors.white).copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                    const SizedBox(height: 14),
                    Text(
                      _resumed ? 'Picked up where you left off' : _hint(step),
                      style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Row(
            children: [
              DhikrTextAction(
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: _count > 0 || _step > 0 ? _undo : null,
              ),
              const Spacer(),
              DhikrTextAction(
                icon: Icons.skip_next_rounded,
                label: _step == session.steps.length - 1 ? 'Finish' : 'Skip step',
                onTap: _skip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _hint(SessionStep step) {
    if (step.count == 1) return 'Once · tap when done';
    if (step.count <= 7) return '${step.count} times · tap after each';
    return 'of ${step.count} · tap after each';
  }

  Widget _buildFinished(BuildContext context, DhikrSession session) {
    return Column(
      children: [
        DhikrHeader(leading: _closeButton(context), title: session.name),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.spiritualGold.withValues(alpha: 0.14),
                        border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.check_rounded, size: 44, color: AppColors.spiritualGold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('${session.name} complete', style: AppTextStyles.h3(color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'May Allah accept it from you.',
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.65)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Pressable(
                    onTap: () => Navigator.of(context).maybePop(),
                    pressedScale: 0.97,
                    child: Container(
                      width: 200,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.spiritualGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.45), width: 0.5),
                      ),
                      child: Text('Done', style: AppTextStyles.body(color: AppColors.spiritualGold, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DhikrTextAction(icon: Icons.replay_rounded, label: 'Start again', onTap: _restart),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unknown(BuildContext context) {
    return Column(
      children: [
        DhikrHeader(leading: _closeButton(context), title: ''),
        Expanded(
          child: Center(
            child: Text('This session isn\'t available.', style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7))),
          ),
        ),
      ],
    );
  }
}

/// Segmented progress across the session's steps.
class _StepBar extends StatelessWidget {
  final int total;
  final int current;
  final bool currentDone;

  const _StepBar({required this.total, required this.current, required this.currentDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < current || (i == current && currentDone)
                    ? AppColors.spiritualGold
                    : i == current
                        ? AppColors.spiritualGold.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
      ],
    );
  }
}

/// One bead per repetition for short counts, filled as you go.
class _Beads extends StatelessWidget {
  final int total;
  final int done;

  const _Beads({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? AppColors.spiritualGold : Colors.transparent,
              border: Border.all(
                color: i < done ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
