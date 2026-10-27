import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../widgets/common/prayer_glyph.dart';
import '../../../core/constants/durations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_status.dart';
import '../../../models/prayer_log.dart';
import '../../../core/services/prayer_service.dart';
import '../../tasbih/screens/session_screen.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../widgets/common/app_backdrop_filter.dart';
import '../../../widgets/common/app_route.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/wird_icons.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final PrayerTimeData? timeData;
  final PrayerEntry? entry;
  final bool isActive;
  final Duration? countdown;
  final DateTime date;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onToggleJamaah;
  final bool reduceMotion;

  const PrayerCard({
    super.key,
    required this.prayer,
    this.timeData,
    this.entry,
    this.isActive = false,
    this.countdown,
    required this.date,
    this.onMarkComplete,
    this.onToggleJamaah,
    this.reduceMotion = false,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  /// Drives the body opening and closing. Forward opens on the emphasized
  /// curve; reverse closes a little quicker so the card gets out of the way.
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 280),
  );

  late final Animation<double> _size = CurvedAnimation(
    parent: _expand,
    curve: AppCurves.emphasized,
    reverseCurve: Curves.easeOutCubic.flipped,
  );

  @override
  void didUpdateWidget(PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if this prayer becomes active and isn't done yet
    if (widget.isActive && !oldWidget.isActive && !(widget.entry?.status.isCompleted ?? false)) {
      _setExpanded(true);
    }
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticService().selection();
    _setExpanded(!_isExpanded);
  }

  void _setExpanded(bool expanded) {
    setState(() => _isExpanded = expanded);
    if (motionStill()) {
      _expand.value = expanded ? 1 : 0;
      return;
    }
    if (expanded) {
      _expand.forward().whenCompleteOrCancel(_revealIfCut);
    } else {
      _expand.reverse();
    }
  }

  /// A card opened near the bottom of the list grows below the fold; nudge
  /// the list just far enough to show all of it.
  void _revealIfCut() {
    if (!mounted || !_isExpanded) return;
    Scrollable.ensureVisible(
      context,
      duration: AppDurations.slow,
      curve: AppCurves.move,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.entry?.status ?? PrayerStatus.upcoming;
    final isCompleted = status.isCompleted;

    // Visual State Logic
    Color backgroundColor = Colors.white.withOpacity(0.03);
    Color borderColor = Colors.white.withOpacity(0.08);
    double blur = 10;

    if (widget.isActive || _isExpanded) {
      backgroundColor = AppColors.activeGlow.withOpacity(0.05);
      borderColor = AppColors.activeGlow.withOpacity(0.2);
      blur = 15;
    } else if (isCompleted) {
      backgroundColor = AppColors.statusOnTime.withOpacity(0.05);
      borderColor = AppColors.statusOnTime.withOpacity(0.15);
    } else if (status == PrayerStatus.missed) {
      backgroundColor = AppColors.statusMissed.withOpacity(0.05);
      borderColor = AppColors.statusMissed.withOpacity(0.15);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AppBackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          // The glow and tint ease in with the body rather than snapping.
          child: AnimatedContainer(
              duration: AppDurations.slow,
              curve: AppCurves.emphasized,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.activeGlow.withOpacity((widget.isActive || _isExpanded) ? 0.05 : 0),
                    blurRadius: 20,
                    spreadRadius: -5,
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    // Only the header toggles the card. When the whole card
                    // did, a near miss on Read Azkar or Jama'ah collapsed it
                    // and the list jumped out from under the finger.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleExpand,
                      child: Padding(
                        // Same row rhythm as Settings and Statistics.
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: _buildHeader(status),
                      ),
                    ),

                    // Expandable Body. It stays built while closing so it can
                    // fade out as the card folds, instead of vanishing first.
                    AnimatedBuilder(
                      animation: _expand,
                      builder: (context, _) {
                        if (_expand.isDismissed) return const SizedBox(width: double.infinity);
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _size.value,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  // The divider draws out from the centre.
                                  Transform.scale(
                                    scaleX: _stagger(0, 0.5),
                                    child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildExpandedDetails(status),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(PrayerStatus status) {
    return Row(
      children: [
        _buildIcon(status),
        const SizedBox(width: 14),
        Expanded(child: _buildNameAndArabic()),
        AnimatedSwitcher(
          duration: AppDurations.normal,
          switchInCurve: AppCurves.emphasized,
          switchOutCurve: AppCurves.exit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: _isExpanded && widget.timeData != null
              ? Icon(
                  Icons.keyboard_arrow_up_rounded,
                  key: const ValueKey('chevron'),
                  color: Colors.white.withOpacity(0.3),
                )
              : KeyedSubtree(
                  key: const ValueKey('pill'),
                  child: _buildTimeOrStatusPill(status),
                ),
        ),
      ],
    );
  }

  /// The prayer's scene in colour on a disc of its sky. The ring says where
  /// it stands: gold for now, green once prayed; missed ones fade back.
  Widget _buildIcon(PrayerStatus status) {
    final sky = prayerSky(widget.prayer, widget.date);
    final ring = widget.isActive
        ? const Color(0xFFF2C46D).withValues(alpha: 0.8)
        : status.isCompleted
            ? AppColors.statusOnTime.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.18);

    return AnimatedOpacity(
      opacity: status == PrayerStatus.missed ? 0.5 : 1,
      duration: AppDurations.normal,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [for (final c in sky) c.withValues(alpha: 0.7)],
          ),
          border: Border.all(color: ring, width: 1.5),
          boxShadow: widget.isActive
              ? [BoxShadow(color: const Color(0xFFF2C46D).withValues(alpha: 0.35), blurRadius: 12)]
              : null,
        ),
        alignment: Alignment.center,
        // Only the current prayer's glyph animates; the rest draw a still frame.
        child: PrayerGlyph.colored(
          prayer: widget.prayer,
          date: widget.date,
          size: 26,
          animate: widget.isActive && !widget.reduceMotion,
        ),
      ),
    );
  }

  Widget _buildNameAndArabic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.prayer.displayNameForDay(widget.date),
          // Row titles across the app are body size; h3 made Schedule loud.
          style: AppTextStyles.body(
            color: widget.isActive ? Colors.white : Colors.white.withOpacity(0.9),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.prayer.arabicNameForDay(widget.date),
          style: AppTextStyles.arabic(
            size: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeOrStatusPill(PrayerStatus status) {
    if (status.isCompleted) {
      return _StatusPill(
        color: AppColors.statusOnTime,
        label: status == PrayerStatus.onTime ? 'DONE' : 'LATE',
        icon: Icons.check,
      );
    }
    if (status == PrayerStatus.missed) {
      return const _StatusPill(
        color: AppColors.statusMissed,
        label: 'MISSED',
        icon: Icons.close,
      );
    }
    if (widget.timeData == null) return const SizedBox();

    return Text(
      AppFormatters.formatTime(widget.timeData!.startTime),
      style: TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()], // Fixed-width digits so numbers don't jitter
        color: Colors.white.withOpacity(widget.isActive ? 1.0 : 0.8),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  // --- Expanded Details ---

  /// The expand progress for one step of the cascade: each section starts a
  /// beat after the one above and takes [span] of the whole open.
  double _stagger(int step, [double span = 0.55]) {
    final start = step * 0.1;
    final t = ((_expand.value - start) / span).clamp(0.0, 1.0);
    return _expand.status == AnimationStatus.reverse
        ? t // Closing: everything folds together, no reverse cascade.
        : AppCurves.emphasized.transform(t);
  }

  /// A section of the open card fading in and rising a few pixels into place.
  Widget _rise(int step, Widget child) {
    final t = _expand.status == AnimationStatus.reverse ? _expand.value : _stagger(step + 1);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
    );
  }

  Widget _buildExpandedDetails(PrayerStatus status) {
    final rakahs = _getRakahInfo(widget.prayer, widget.date);
    final notes = _getPrayerNotes(widget.prayer, widget.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Time Info Grid
        if (widget.timeData != null) ...[
          _rise(0, _buildTimeInfoSection()),
          const SizedBox(height: 24),
        ],

        // 2. Rakahs
        if (rakahs.totalCount > 0) ...[
          _rise(1, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text("COMPOSITION", style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                if (rakahs.sunnahPre > 0) _RakahBadge(count: rakahs.sunnahPre, type: 'Sunnah'),
                if (rakahs.fardh > 0) _RakahBadge(count: rakahs.fardh, type: 'Fardh', isGold: true),
                if (rakahs.sunnahPost > 0) _RakahBadge(count: rakahs.sunnahPost, type: 'Sunnah'),
                if (rakahs.nafl > 0) _RakahBadge(count: rakahs.nafl, type: 'Nafl'),
                if (rakahs.witr > 0) _RakahBadge(count: rakahs.witr, type: 'Witr', isGold: true),
              ],
            ),
          ),
            ],
          )),
          const SizedBox(height: 24),
        ],

        // 3. Notes / Sunnah Info
        if (notes != null) ...[
          _rise(2, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text("SUNNAH & NOTES", style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.spiritualGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.spiritualGold.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KhatimIcon(size: 16, color: AppColors.spiritualGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notes,
                    style: AppTextStyles.small(color: Colors.white.withOpacity(0.9)).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
            ],
          )),
          const SizedBox(height: 24),
        ],

        // 4. Actions (Buttons)
        // We use the same layout for both states to prevent layout shifts
        _rise(3, _buildActionButtons(isCompleted: status.isCompleted)),
      ],
    );
  }

  Widget _buildTimeInfoSection() {
    final start = AppFormatters.formatTime(widget.timeData!.startTime);
    final end = AppFormatters.formatTime(widget.timeData!.endTime);
    final duration = widget.timeData!.duration;
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    final durationStr = "${hours > 0 ? '${hours}h ' : ''}${mins}m";

    String endLabel = "ENDS";
    String endValue = end;
    Color endColor = Colors.white;

    if (widget.prayer == Prayer.fajr) {
      endLabel = "SUNRISE";
      endColor = AppColors.spiritualGold;
    } else if (widget.prayer == Prayer.isha) {
      endLabel = "MIDNIGHT";
      endColor = Colors.white.withOpacity(0.8);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WINDOW", style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4))),
                const SizedBox(height: 4),
                Text("$start — $end", style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DURATION", style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4))),
                const SizedBox(height: 4),
                Text(durationStr, style: AppTextStyles.body(color: Colors.white)),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(endLabel, style: AppTextStyles.tiny(color: endColor.withOpacity(0.6))),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.prayer == Prayer.fajr)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.wb_twilight_rounded, size: 14, color: AppColors.spiritualGold),
                      ),
                    Text(
                        endValue,
                        style: AppTextStyles.body(color: endColor).copyWith(fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- Fixed Action Buttons ---
  Widget _buildActionButtons({required bool isCompleted}) {
    final status = widget.entry?.status ?? PrayerStatus.upcoming;
    final canMarkComplete = widget.onMarkComplete != null;
    final canToggleJamaah = widget.onToggleJamaah != null;
    
    // Determine button state based on status and callback availability
    String buttonLabel;
    IconData buttonIcon;
    Color buttonColor;
    bool isFilled;
    
    if (isCompleted) {
      buttonLabel = "Read Azkar";
      buttonIcon = Icons.auto_stories_rounded;
      buttonColor = AppColors.spiritualGold;
      isFilled = true;
    } else if (status == PrayerStatus.upcoming) {
      buttonLabel = "Not Started";
      buttonIcon = Icons.schedule_rounded;
      buttonColor = Colors.white.withOpacity(0.3);
      isFilled = false;
    } else if (status == PrayerStatus.missed) {
      buttonLabel = "Missed";
      buttonIcon = Icons.cancel_rounded;
      buttonColor = AppColors.statusMissed;
      isFilled = false;
    } else {
      buttonLabel = "Mark Prayed";
      buttonIcon = Icons.check_circle_outline_rounded;
      buttonColor = AppColors.buttonPrimary;
      isFilled = true;
    }
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _PrayedBounce(
            prayed: isCompleted,
            child: _ModernActionButton(
            label: buttonLabel,
            icon: buttonIcon,
            glyph: isCompleted ? WirdGlyph.tasbih : null,
            color: buttonColor,
            onTap: isCompleted ? () {
              HapticService().selection();
              Navigator.push(
                context,
                AppRoute(
                  builder: (_) => const SessionScreen(sessionId: 'after_prayer'),
                ),
              );
            } : canMarkComplete ? () {
              // Before the haptic, so the bell wins over the haptic's pop.
              SoundService().prayed(jamaah: widget.entry?.isJamaah ?? false);
              HapticService().medium();
              widget.onMarkComplete?.call();
            } : null,
            isFilled: isFilled && (canMarkComplete || isCompleted),
          ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildJamaahToggle(compact: false, enabled: canToggleJamaah),
        ),
      ],
    );
  }

  Widget _buildJamaahToggle({required bool compact, bool enabled = true}) {
    final isJamaah = widget.entry?.isJamaah ?? false;
    final color = enabled ? AppColors.jumuahAccent : Colors.white.withOpacity(0.2);

    return Pressable(
      pressedScale: 0.95,
      haptic: PressableHaptic.none,
      onTap: enabled ? () {
        HapticService().light();
        widget.onToggleJamaah?.call();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 0,
            vertical: compact ? 6 : 12 // Matches ModernActionButton height better
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isJamaah ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          border: Border.all(
            color: isJamaah ? color.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                Icons.groups_rounded,
                size: compact ? 16 : 18,
                color: isJamaah ? color : Colors.white.withOpacity(0.5)
            ),
            const SizedBox(width: 6),
            Flexible( // FIX: Prevents text overflow
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Jama'ah",
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isJamaah ? color : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  _RakahInfo _getRakahInfo(Prayer p, DateTime date) {
    final isFriday = date.weekday == DateTime.friday;
    switch (p) {
      case Prayer.fajr: return _RakahInfo(2, 2, 0, 0, 0);
      case Prayer.dhuhr: return isFriday
          ? _RakahInfo(4, 2, 0, 0, 0)
          : _RakahInfo(4, 4, 2, 0, 0);
      case Prayer.asr: return _RakahInfo(4, 4, 0, 0, 0);
      case Prayer.maghrib: return _RakahInfo(0, 3, 2, 2, 0);
      case Prayer.isha: return _RakahInfo(4, 4, 2, 0, 3);
      case Prayer.ishraq: return _RakahInfo(0, 0, 0, 2, 0);
      case Prayer.duha: return _RakahInfo(0, 0, 0, 4, 0);
      case Prayer.tahajjud: return _RakahInfo(0, 0, 0, 8, 0);
      default: return _RakahInfo(0, 0, 0, 0, 0);
    }
  }

  String? _getPrayerNotes(Prayer p, DateTime date) {
    switch (p) {
      case Prayer.fajr: return "Sunnah: Recite Surah Al-Kafirun in 1st Rakah and Al-Ikhlas in 2nd.";
      case Prayer.ishraq: return "Virtue: Reward of a complete Hajj and Umrah.";
      case Prayer.dhuhr: return date.weekday == DateTime.friday ? "Sunnah: Recite Surah Al-Kahf today." : "Sunnah: The Prophet ﷺ never abandoned the 4 Rakahs before Dhuhr.";
      case Prayer.asr: return "Hadith: 'May Allah have mercy on the one who prays 4 Rakahs before Asr.'";
      case Prayer.maghrib: return "Recite short Surahs. Hurry to break fast if fasting.";
      case Prayer.isha: return "Delaying Isha to the first third of the night is preferred if possible.";
      case Prayer.tahajjud: return "The most virtuous prayer after the obligatory ones.";
      default: return null;
    }
  }
}

// --- Helper Classes ---

class _RakahInfo {
  final int sunnahPre;
  final int fardh;
  final int sunnahPost;
  final int nafl;
  final int witr;

  _RakahInfo(this.sunnahPre, this.fardh, this.sunnahPost, this.nafl, this.witr);

  int get totalCount => sunnahPre + fardh + sunnahPost + nafl + witr;
}

class _RakahBadge extends StatelessWidget {
  final int count;
  final String type;
  final bool isGold;

  const _RakahBadge({required this.count, required this.type, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGold ? AppColors.spiritualGold.withOpacity(0.15) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGold ? AppColors.spiritualGold.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$count", style: AppTextStyles.h3(color: isGold ? AppColors.spiritualGold : Colors.white).copyWith(fontSize: 13)),
          const SizedBox(width: 6),
          Text(type, style: AppTextStyles.tiny(color: isGold ? AppColors.spiritualGold : Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _StatusPill({required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.tiny(color: color).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

/// Gives the action button one small bounce as the prayer is marked
/// prayed: a quick swell, then a soft overshoot back to rest. Plays only on
/// the change, never when a card first appears already prayed.
class _PrayedBounce extends StatefulWidget {
  final bool prayed;
  final Widget child;

  const _PrayedBounce({required this.prayed, required this.child});

  @override
  State<_PrayedBounce> createState() => _PrayedBounceState();
}

class _PrayedBounceState extends State<_PrayedBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: AppCurves.settle)),
      weight: 75,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant _PrayedBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prayed && !oldWidget.prayed && !motionStill()) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class _ModernActionButton extends StatelessWidget {
  final String label;
  final IconData icon;

  /// A section glyph in place of [icon], e.g. prayer beads for azkar.
  final WirdGlyph? glyph;
  final Color color;
  final VoidCallback? onTap;
  final bool isFilled;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    this.glyph,
    required this.color,
    this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    // Callers fire their own haptic, so Pressable only adds the press.
    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      haptic: PressableHaptic.none,
      child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isFilled
                ? LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isFilled ? null : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isFilled ? Colors.transparent : Colors.white.withOpacity(0.1),
            ),
            boxShadow: isFilled
                ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph != null
                  ? WirdGlyphIcon(glyph!, size: 18, color: isFilled ? Colors.white : color)
                  : Icon(icon, size: 18, color: isFilled ? Colors.white : color),
              const SizedBox(width: 8),
              // FIX: Flexible + FittedBox to prevent text overflow on small screens
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isFilled ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}