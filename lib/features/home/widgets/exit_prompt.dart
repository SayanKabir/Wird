import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/glass_sheet.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/wird_icons.dart';

/// Where a "stay a little longer" suggestion takes the user.
enum ExitNudgeAction { quran, dhikr }

/// One gentle reason to stay before closing the app.
class ExitNudge {
  final String title;
  final String message;
  final String actionLabel;
  /// Shown in the nudge's gold disc, unless [glyph] is set.
  final IconData? icon;

  /// The section's own glyph (Quran, prayer beads), used in place of [icon].
  final WirdGlyph? glyph;
  final ExitNudgeAction action;

  /// For a Quran nudge, the surah to open. Null goes to the Quran tab.
  final int? surahId;

  const ExitNudge({
    required this.title,
    required this.message,
    required this.actionLabel,
    this.icon,
    this.glyph,
    required this.action,
    this.surahId,
  });
}

/// The pool the prompt draws from. Kept short and warm: an invitation, never
/// a guilt trip, and always one tap away from actually leaving.
const List<ExitNudge> exitNudges = [
  ExitNudge(
    title: 'Leaving already?',
    message: 'A single ayah takes ten seconds. Read one before you go?',
    actionLabel: 'Read an ayah',
    glyph: WirdGlyph.quran,
    action: ExitNudgeAction.quran,
  ),
  ExitNudge(
    title: 'One more page?',
    message: 'The Quran will come as an intercessor for its companions.',
    actionLabel: 'Keep reading',
    glyph: WirdGlyph.quran,
    action: ExitNudgeAction.quran,
  ),
  ExitNudge(
    title: 'Before you go…',
    message: 'SubhanAllah thirty-three times takes under a minute.',
    actionLabel: 'Quick dhikr',
    action: ExitNudgeAction.dhikr,
  ),
  ExitNudge(
    title: 'A little more dhikr?',
    message: 'Keep your tongue moist with the remembrance of Allah.',
    actionLabel: 'Open tasbih',
    action: ExitNudgeAction.dhikr,
  ),
  ExitNudge(
    title: 'Light on the tongue',
    message: 'SubhanAllahi wa bihamdihi, SubhanAllahil Azim. Heavy on the scale.',
    actionLabel: 'Say it now',
    icon: Icons.balance_rounded,
    action: ExitNudgeAction.dhikr,
  ),
  ExitNudge(
    title: 'Sent salawat today?',
    message: 'Whoever sends one blessing on the Prophet ﷺ receives ten.',
    actionLabel: 'Send salawat',
    icon: Icons.favorite_rounded,
    action: ExitNudgeAction.dhikr,
  ),
  ExitNudge(
    title: 'Close with istighfar',
    message: 'Three quiet Astaghfirullah before you put the phone down.',
    actionLabel: 'Seek forgiveness',
    icon: Icons.nights_stay_rounded,
    action: ExitNudgeAction.dhikr,
  ),
  ExitNudge(
    title: 'Five more minutes?',
    message: 'Al-Mulk is thirty ayahs and a protection for the night.',
    actionLabel: 'Read Al-Mulk',
    icon: Icons.shield_moon_rounded,
    action: ExitNudgeAction.quran,
    surahId: 67,
  ),
];

/// What the user chose in the exit prompt.
sealed class ExitChoice {
  const ExitChoice();
}

class ExitChoiceLeave extends ExitChoice {
  const ExitChoiceLeave();
}

class ExitChoiceStay extends ExitChoice {
  final ExitNudge nudge;
  const ExitChoiceStay(this.nudge);
}

final math.Random _random = math.Random();

/// Asks the user whether they really want to leave, with a random nudge to
/// stay for a little Quran or dhikr. Returns null if the sheet is dismissed.
Future<ExitChoice?> showExitPrompt(BuildContext context) {
  HapticService().light();
  final nudge = exitNudges[_random.nextInt(exitNudges.length)];
  return showGlassSheet<ExitChoice>(
    context: context,
    child: _ExitPromptBody(nudge: nudge),
  );
}

/// Closes the app the way the system back gesture would have.
void leaveApp() => SystemNavigator.pop();

class _ExitPromptBody extends StatelessWidget {
  final ExitNudge nudge;

  const _ExitPromptBody({required this.nudge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.spiritualGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: nudge.icon != null
                ? Icon(nudge.icon, color: AppColors.spiritualGold, size: 24)
                : WirdGlyphIcon(nudge.glyph ?? WirdGlyph.tasbih, size: 26, color: AppColors.spiritualGold),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(nudge.title, style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            nudge.message,
            style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: nudge.actionLabel,
            primary: true,
            onTap: () => Navigator.pop(context, ExitChoiceStay(nudge)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SheetButton(
            label: 'Exit Wird',
            onTap: () => Navigator.pop(context, const ExitChoiceLeave()),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SheetButton({required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      haptic: primary ? PressableHaptic.light : PressableHaptic.selection,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? AppColors.spiritualGold.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: primary
                ? AppColors.spiritualGold.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(
            color: primary ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
