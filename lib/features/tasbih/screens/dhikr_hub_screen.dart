import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../models/tasbih.dart';
import '../../../widgets/common/pressable.dart';
import '../bloc/tasbih_bloc.dart';
import '../dhikr_nav.dart';
import '../widgets/counter_editor_sheet.dart';
import '../widgets/dhikr_widgets.dart';
import '../../../core/constants/radii.dart';
import '../../../widgets/common/glass_panel.dart';

/// The dhikr hub: guided sessions and free counters.
class DhikrHubScreen extends StatefulWidget {
  const DhikrHubScreen({super.key});

  @override
  State<DhikrHubScreen> createState() => _DhikrHubScreenState();
}

class _DhikrHubScreenState extends State<DhikrHubScreen> {
  final _store = DhikrSessionStore();

  /// Session progress lives outside the bloc, so refresh on return.
  Future<void> _open(Future<void> Function() push) async {
    await push();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nowId = DhikrNav.nowSessionId(context);
    final now = DhikrCatalog.session(nowId)!;

    return DhikrBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<TasbihBloc, TasbihState>(
            builder: (context, state) {
              final counters = state is TasbihLoaded ? TasbihRepository.visibleCounters(state.tasbihs) : const <Tasbih>[];
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          DhikrIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REMEMBRANCE',
                            style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Dhikr', style: AppTextStyles.h1(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _NowCard(
                        session: now,
                        status: _status(now),
                        onTap: () => _open(() => DhikrNav.openSession(context, now.id)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _Label('SESSIONS')),
                  SliverToBoxAdapter(
                    child: _Group(
                      children: [
                        for (final s in DhikrCatalog.sessions)
                          _Row(
                            title: s.name,
                            subtitle: _status(s),
                            trailing: _store.isDoneToday(s.id)
                                ? const Icon(Icons.check_rounded, size: 18, color: AppColors.spiritualGold)
                                : Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white.withValues(alpha: 0.35)),
                            onTap: () => _open(() => DhikrNav.openSession(context, s.id)),
                          ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: _Label('COUNTERS')),
                  SliverToBoxAdapter(
                    child: _Group(
                      children: [
                        for (final t in counters)
                          _Row(
                            title: t.name,
                            subtitle: _counterSubtitle(t),
                            trailing: Text(
                              t.todayCount() > 0 ? '${t.todayCount()} today' : '',
                              style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)),
                            ),
                            onTap: () => _open(() => DhikrNav.openCounter(context, t.id)),
                          ),
                        _Row(
                          title: 'Add your own',
                          leading: const Icon(Icons.add_rounded, size: 18, color: AppColors.spiritualGold),
                          titleColor: AppColors.spiritualGold,
                          onTap: state is TasbihLoaded ? () => showCounterEditor(context) : null,
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 32)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _status(DhikrSession s) {
    final resume = _store.resumePoint(s.id);
    if (resume != null) return 'Paused at step ${resume.$1 + 1} of ${s.steps.length}';
    if (_store.isDoneToday(s.id)) return 'Done today';
    if (s.id == 'fatimah') return '33 · 33 · 34';
    return '${s.steps.length} steps';
  }

  String _counterSubtitle(Tasbih t) {
    if (t.isRoundFull) return 'Round ${t.round} complete';
    if (t.currentCount > 0) {
      return '${t.currentCount} of ${t.targetCount}${t.completedRounds > 0 ? ' · round ${t.round}' : ''}';
    }
    return 'Target ${t.targetCount}';
  }
}

class _NowCard extends StatelessWidget {
  final DhikrSession session;
  final String status;
  final VoidCallback onTap;

  const _NowCard({required this.session, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        gradient: LinearGradient(
          colors: [AppColors.spiritualGold.withValues(alpha: 0.14), AppColors.spiritualGold.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 20,
        edgeColor: AppColors.spiritualGold.withValues(alpha: 0.25),
        edgeWidth: 0.5,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Now', style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6)).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(session.name, style: AppTextStyles.bodyLarge(color: AppColors.spiritualGold, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(status, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.spiritualGold.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.spiritualGold, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Text(
        text,
        style: AppTextStyles.tiny(color: AppColors.spiritualGold.withValues(alpha: 0.8)).copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      radius: AppRadii.group,
      fill: 0.04,
      edge: 0.06,
      edgeWidth: 0.5,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 0.5, indent: 16, color: Colors.white.withValues(alpha: 0.07)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _Row({required this.title, this.subtitle, this.leading, this.trailing, this.titleColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(color: titleColor ?? Colors.white.withValues(alpha: 0.95), weight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
