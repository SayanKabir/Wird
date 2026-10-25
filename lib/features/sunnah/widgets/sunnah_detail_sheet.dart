import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../core/services/haptic_service.dart';
import '../../../models/sunnah.dart';
import '../../../widgets/common/pressable.dart';
import '../bloc/sunnah_bloc.dart';
import 'sunnah_check.dart';
import 'sunnah_format.dart';
import '../../../widgets/common/app_backdrop_filter.dart';
import '../../../core/constants/radii.dart';

/// Opens the detail sheet for [sunnah]. Its controls act in place: ticking it
/// or adding it to the practice updates the sheet and the screen behind it,
/// and the sheet stays open.
Future<void> showSunnahDetailSheet(BuildContext context, Sunnah sunnah) {
  final bloc = context.read<SunnahBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: SunnahDetailSheet(sunnah: sunnah),
    ),
  );
}

class SunnahDetailSheet extends StatelessWidget {
  final Sunnah sunnah;

  const SunnahDetailSheet({super.key, required this.sunnah});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmallPhone = size.width < 360;
    final hPad = isSmallPhone ? 20.0 : 24.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.88),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        child: AppBackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          fallbackTint: AppBackdropFilter.sheetTint,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      SunnahFormat.categoryOverline(sunnah.category),
                      style: AppTextStyles.tiny(color: AppColors.spiritualGold.withValues(alpha: 0.85))
                          .copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sunnah.title,
                      style: AppTextStyles.h2(color: Colors.white).copyWith(fontSize: isSmallPhone ? 20 : 23),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      SunnahFormat.description(sunnah),
                      style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.88)).copyWith(height: 1.6),
                    ),
                    if (sunnah.arabic != null) ...[
                      const SizedBox(height: 20),
                      _ArabicBlock(sunnah: sunnah, isSmallPhone: isSmallPhone),
                    ],
                    if (sunnah.virtue.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        sunnah.virtue,
                        style: AppTextStyles.small(color: AppColors.spiritualGold.withValues(alpha: 0.75))
                            .copyWith(fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ],
                    if (sunnah.tips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      for (final tip in sunnah.tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 7, right: 10),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7))
                                      .copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      SunnahFormat.fullReference(sunnah),
                      style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 8),
                    _Controls(sunnah: sunnah),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArabicBlock extends StatelessWidget {
  final Sunnah sunnah;
  final bool isSmallPhone;

  const _ArabicBlock({required this.sunnah, required this.isSmallPhone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.group),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sunnah.arabic!,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTextStyles.arabic(
              color: AppColors.spiritualGold.withValues(alpha: 0.92),
              size: isSmallPhone ? 22 : 25,
            ).copyWith(height: 1.8),
          ),
          if (sunnah.transliteration != null) ...[
            const SizedBox(height: 10),
            Text(
              sunnah.transliteration!,
              textAlign: TextAlign.center,
              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.75))
                  .copyWith(fontStyle: FontStyle.italic, height: 1.5),
            ),
          ],
          if (sunnah.translation != null) ...[
            const SizedBox(height: 8),
            Text(
              sunnah.translation!,
              textAlign: TextAlign.center,
              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)).copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// "In my practice", "Done today" and, for dhikr, a link into Dhikr — read
/// live from the bloc so they reflect taps immediately.
class _Controls extends StatelessWidget {
  final Sunnah sunnah;

  const _Controls({required this.sunnah});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SunnahBloc, SunnahState>(
      builder: (context, state) {
        if (state is! SunnahLoaded) return const SizedBox.shrink();
        final progress = state.progress;
        final inPractice = progress.isInPractice(sunnah.id);
        final doneToday = progress.isPracticedToday(sunnah.id);
        final count = progress.practiceCountsBySunnah[sunnah.id] ?? 0;
        final lastDay = progress.lastPracticedDayBySunnah[sunnah.id];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ControlRow(
              label: 'In my practice',
              caption: inPractice
                  ? 'On your Sunnah page to tick off each day'
                  : 'Keep it on your Sunnah page to tick off each day',
              onTap: () {
                HapticService().selection();
                context.read<SunnahBloc>().add(ToggleSunnahPractice(sunnah.id));
              },
              trailing: IgnorePointer(
                child: Switch(
                  value: inPractice,
                  onChanged: (_) {},
                  activeThumbColor: const Color(0xFF3D2E00),
                  activeTrackColor: AppColors.spiritualGold,
                  inactiveThumbColor: Colors.white.withValues(alpha: 0.8),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Done today', style: AppTextStyles.body(color: Colors.white)),
                ),
                SunnahCheck(
                  done: doneToday,
                  onTap: () => context.read<SunnahBloc>().add(ToggleSunnahToday(sunnah.id)),
                ),
              ],
            ),
            if (SunnahFormat.hasTasbih(sunnah))
              _ControlRow(
                label: DhikrCatalog.sessionForSunnah(tasbihId: sunnah.tasbihId, title: sunnah.title) != null
                    ? 'Recite with the guide'
                    : 'Count in Tasbih',
                onTap: () {
                  Navigator.of(context).pop();
                  SunnahFormat.openTasbih(context, sunnah);
                },
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            if (count > 0 && lastDay != null) ...[
              const SizedBox(height: 12),
              Text(
                [
                  'Kept ${count == 1 ? 'once' : '$count times'}',
                  if (!doneToday) 'last ${SunnahFormat.relativeDay(lastDay)}',
                ].join(' · '),
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ControlRow extends StatelessWidget {
  final String label;
  final String? caption;
  final Widget trailing;
  final VoidCallback onTap;

  const _ControlRow({
    required this.label,
    required this.trailing,
    required this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      haptic: PressableHaptic.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body(color: Colors.white)),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(caption!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45))),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
