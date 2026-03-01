import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_status.dart';
import '../../../models/prayer_log.dart';
import '../../../core/services/prayer_service.dart';
import '../../tasbih/screens/tasbih_screen.dart';

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

  @override
  void didUpdateWidget(PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if this prayer becomes active and isn't done yet
    if (widget.isActive && !oldWidget.isActive && !(widget.entry?.status.isCompleted ?? false)) {
      setState(() => _isExpanded = true);
    }
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: (widget.isActive || _isExpanded) ? [
                  BoxShadow(
                    color: AppColors.activeGlow.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: -5,
                  )
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(status),

                      // Expandable Body
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutQuart,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(height: 1, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 20),
                            _buildExpandedDetails(status),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
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
        const SizedBox(width: 16),
        Expanded(child: _buildNameAndArabic()),
        if (!(_isExpanded && widget.timeData != null))
          _buildTimeOrStatusPill(status),

        if (_isExpanded && widget.timeData != null)
          Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildIcon(PrayerStatus status) {
    Color iconColor = Colors.white.withOpacity(0.7);
    if (widget.isActive) iconColor = AppColors.activeGlow;
    if (status.isCompleted) iconColor = AppColors.statusOnTime;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.prayer.iconForDay(widget.date),
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  Widget _buildNameAndArabic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.prayer.displayNameForDay(widget.date),
          style: AppTextStyles.h3(
            color: widget.isActive ? Colors.white : Colors.white.withOpacity(0.9),
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
        fontFamily: 'JetBrains Mono',
        color: Colors.white.withOpacity(widget.isActive ? 1.0 : 0.8),
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  // --- Expanded Details ---

  Widget _buildExpandedDetails(PrayerStatus status) {
    final rakahs = _getRakahInfo(widget.prayer, widget.date);
    final notes = _getPrayerNotes(widget.prayer, widget.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Time Info Grid
        if (widget.timeData != null) ...[
          _buildTimeInfoSection(),
          const SizedBox(height: 24),
        ],

        // 2. Rakahs
        if (rakahs.totalCount > 0) ...[
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
          const SizedBox(height: 24),
        ],

        // 3. Notes / Sunnah Info
        if (notes != null) ...[
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
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.spiritualGold),
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
          const SizedBox(height: 24),
        ],

        // 4. Actions (Buttons)
        // We use the same layout for both states to prevent layout shifts
        _buildActionButtons(isCompleted: status.isCompleted),
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
                Text("$start — $end", style: AppTextStyles.h3(color: Colors.white)),
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
          child: _ModernActionButton(
            label: buttonLabel,
            icon: buttonIcon,
            color: buttonColor,
            onTap: isCompleted ? () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TasbihScreen(initialFlow: 'after_prayer'),
                ),
              );
            } : canMarkComplete ? () {
              HapticFeedback.mediumImpact();
              widget.onMarkComplete?.call();
            } : null,
            isFilled: isFilled && (canMarkComplete || isCompleted),
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

    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
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

class _ModernActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isFilled;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        child: Ink(
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
              Icon(icon, size: 18, color: isFilled ? Colors.white : color),
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
      ),
    );
  }
}