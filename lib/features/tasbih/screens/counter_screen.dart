import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../core/services/haptic_service.dart';
import '../../../models/tasbih.dart';
import '../bloc/tasbih_bloc.dart';
import '../widgets/counter_editor_sheet.dart';
import '../widgets/dhikr_motion.dart';
import '../widgets/dhikr_widgets.dart';
import '../../../core/constants/radii.dart';

/// Counting one dhikr freely, in rounds of its target.
class CounterScreen extends StatefulWidget {
  final String counterId;

  const CounterScreen({super.key, required this.counterId});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _tap(Tasbih t) {
    // Feel the round land: a firm tap on the count that fills it.
    final fills = !t.isRoundFull && t.currentCount + 1 >= t.targetCount;
    fills ? HapticService().heavy() : HapticService().light();
    context.read<TasbihBloc>().add(CounterTapped(t.id));
  }

  @override
  Widget build(BuildContext context) {
    return DhikrBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BlocBuilder<TasbihBloc, TasbihState>(
            builder: (context, state) {
              final t = state is TasbihLoaded ? state.byId(widget.counterId) : null;
              if (t == null) {
                return _Missing(loading: state is! TasbihLoaded && state is! TasbihError);
              }
              return _buildCounter(context, t);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(BuildContext context, Tasbih t) {
    final text = DhikrCatalog.counterText[t.id];
    final full = t.isRoundFull;
    final shown = full ? t.targetCount : t.currentCount;
    final caption = full
        ? 'Round ${t.round} complete · tap to begin round ${t.round + 1}'
        : t.completedRounds > 0
            ? 'Round ${t.round}'
            : (t.totalCount == 0 ? 'Tap anywhere here to count' : ' ');
    final height = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        DhikrHeader(
          leading: DhikrIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          title: t.name,
          trailing: DhikrIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'Counter options',
            onTap: () => _showOptions(context, t),
          ),
        ),
        const SizedBox(height: 8),
        if (text != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * 0.3),
            child: DhikrTextCard(
              arabic: text.arabic,
              transliteration: text.transliteration,
              translation: text.translation,
              virtue: text.virtue,
            ),
          ),
        // Only this area counts, so reading or scrolling the text above
        // never adds a tap by accident.
        Expanded(
          child: RippleTapArea(
            semanticLabel: 'Count ${t.name}. $shown of ${t.targetCount}',
            onTap: () => _tap(t),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DhikrRing(
                    progress: t.targetCount == 0 ? 0 : shown / t.targetCount,
                    size: (height * 0.3).clamp(200.0, 270.0),
                    pulseKey: t.round,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TickingNumber(
                          value: shown,
                          style: AppTextStyles.counter(color: full ? AppColors.spiritualGold : Colors.white),
                        ),
                        Text(
                          'of ${t.targetCount}',
                          style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      caption,
                      key: ValueKey(caption),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small(
                        color: full ? AppColors.spiritualGold.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 20, 8),
          child: Row(
            children: [
              DhikrTextAction(
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: t.currentCount > 0 ? () => context.read<TasbihBloc>().add(CounterUndone(t.id)) : null,
              ),
              const Spacer(),
              Text(
                '${t.todayCount()} today · ${compactCount(t.totalCount)} all time',
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, Tasbih t) {
    final bloc = context.read<TasbihBloc>();
    final custom = !DhikrCatalog.isBuiltIn(t.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetCtx) => DhikrSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionRow(
              icon: Icons.restart_alt_rounded,
              label: 'Start a fresh round',
              caption: 'Clears this round and the round count. Today and all-time totals stay.',
              onTap: t.currentCount == 0 && t.completedRounds == 0
                  ? null
                  : () {
                      Navigator.pop(sheetCtx);
                      HapticService().medium();
                      bloc.add(CounterReset(t.id));
                    },
            ),
            _OptionRow(
              icon: Icons.tune_rounded,
              label: custom ? 'Edit name and target' : 'Change target',
              onTap: () {
                Navigator.pop(sheetCtx);
                showCounterEditor(context, existing: t);
              },
            ),
            if (custom)
              _OptionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete counter',
                destructive: true,
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await confirmDeleteCounter(context, t);
                  if (ok && context.mounted) {
                    bloc.add(DeleteTasbih(t.id));
                    Navigator.of(context).maybePop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? caption;
  final bool destructive;
  final VoidCallback? onTap;

  const _OptionRow({required this.icon, required this.label, this.caption, this.destructive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = destructive ? const Color(0xFFFF8A80) : Colors.white;
    final color = onTap == null ? base.withValues(alpha: 0.3) : base;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body(color: color)),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(caption!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  final bool loading;

  const _Missing({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DhikrHeader(
          leading: DhikrIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          title: '',
        ),
        Expanded(
          child: Center(
            child: loading
                ? const CircularProgressIndicator(color: AppColors.spiritualGold, strokeWidth: 2)
                : Text(
                    'This counter is no longer here.',
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
                  ),
          ),
        ),
      ],
    );
  }
}
