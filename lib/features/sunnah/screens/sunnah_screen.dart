import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../core/constants/spacing.dart';
import '../../../models/sunnah.dart';
import '../../../models/sunnah_progress.dart';
import '../../../widgets/common/page_header.dart';
import '../../../widgets/common/premium_flowing_loader.dart';
import '../../../widgets/common/pressable.dart';
import '../../home/bloc/prayer_bloc.dart';
import '../../tasbih/dhikr_nav.dart';
import '../bloc/sunnah_bloc.dart';
import '../widgets/sunnah_check.dart';
import '../widgets/sunnah_detail_sheet.dart';
import '../widgets/sunnah_format.dart';
import '../../../core/constants/radii.dart';
import '../../../widgets/common/wird_icons.dart';
import '../../../widgets/common/glass_panel.dart';

/// The Sunnah tab: this week's sunnah, the few the user has chosen to keep
/// (ticked off day by day), and the library to choose them from.
class SunnahScreen extends StatefulWidget {
  const SunnahScreen({super.key});

  @override
  State<SunnahScreen> createState() => _SunnahScreenState();
}

class _SunnahScreenState extends State<SunnahScreen> {
  /// Library filter; null shows every category.
  String? _category;

  List<Sunnah>? _sortedFor;
  List<Sunnah> _sorted = const [];
  List<String> _categories = const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SunnahBloc, SunnahState>(
          builder: (context, state) {
            if (state is SunnahLoaded) return _buildLoaded(context, state);
            if (state is SunnahError) return _buildError(context);
            return const Center(
              child: PremiumFlowingLoader(size: 50.0, color: AppColors.spiritualGold),
            );
          },
        ),
      ),
    );
  }

  /// Library order: by category, then as listed in the data. Cached per list.
  void _prepareLibrary(List<Sunnah> sunnahs) {
    if (identical(_sortedFor, sunnahs)) return;
    final indexed = sunnahs.asMap().entries.toList()
      ..sort((a, b) {
        final c = SunnahFormat.categoryIndex(a.value.category)
            .compareTo(SunnahFormat.categoryIndex(b.value.category));
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    _sorted = indexed.map((e) => e.value).toList(growable: false);
    _categories = <String>{for (final s in _sorted) s.category}.toList(growable: false);
    _sortedFor = sunnahs;
  }

  Widget _buildLoaded(BuildContext context, SunnahLoaded state) {
    _prepareLibrary(state.sunnahs);
    final size = MediaQuery.sizeOf(context);
    final hPad = AppSpacing.gutter(context);
    final progress = state.progress;
    final practice = state.practice;
    final doneCount = practice.where((s) => progress.isPracticedToday(s.id)).length;
    final library = _category == null
        ? _sorted
        : _sorted.where((s) => s.category == _category).toList(growable: false);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.header(context),
            child: const PageHeader(
              overline: 'THE PROPHETIC PATH',
              title: 'Sunnah',
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
            child: const _DhikrCard(),
          ),
        ),

        if (state.weeklySunnah != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _WeeklyCard(sunnah: state.weeklySunnah!, progress: progress),
            ),
          ),

        SliverToBoxAdapter(
          child: _SectionLabel(
            text: 'YOUR PRACTICE',
            horizontalPadding: hPad,
            trailing: practice.isEmpty ? null : '$doneCount of ${practice.length} today',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: practice.isEmpty
                ? const _PracticeEmpty()
                : _PracticeList(sunnahs: practice, progress: progress),
          ),
        ),

        SliverToBoxAdapter(child: _SectionLabel(text: 'LIBRARY', horizontalPadding: hPad)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _CategoryPill(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in _categories)
                  _CategoryPill(
                    label: SunnahFormat.shortCategory(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverList.builder(
            itemCount: library.length,
            itemBuilder: (context, i) => _LibraryRow(
              sunnah: library[i],
              showCategory: _category == null,
              inPractice: progress.isInPractice(library[i].id),
              doneToday: progress.isPracticedToday(library[i].id),
            ),
          ),
        ),

        SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 100)),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sunnahs couldn't load",
              style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.85), weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Pressable(
              onTap: () => context.read<SunnahBloc>().add(LoadSunnahs()),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                radius: AppRadii.pill,
                fill: 0.08,
                edge: 0.12,
                edgeWidth: 0.5,
                child: Text('Try again', style: AppTextStyles.small(color: Colors.white, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Dhikr ───────────────────

/// Compact way into the dhikr section: tapping the card opens the hub, the
/// play button starts the session that suits the time of day.
class _DhikrCard extends StatefulWidget {
  const _DhikrCard();

  @override
  State<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<_DhikrCard> {
  // Which session is "now" can change after one is finished; refresh on return.
  Future<void> _open(Future<void> Function() push) async {
    await push();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerBloc, PrayerState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType || (a is PrayerLoaded && b is PrayerLoaded && a.prayerPeriod != b.prayerPeriod),
      builder: (context, _) {
        final now = DhikrCatalog.session(DhikrNav.nowSessionId(context))!;
        return Pressable(
          onTap: () => _open(() => DhikrNav.openHub(context)),
          pressedScale: 0.98,
          child: GlassPanel(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            radius: AppRadii.group,
            fill: 0.05,
            edge: 0.08,
            edgeWidth: 0.5,
            child: Row(
              children: [
                TasbihIcon(size: 22, color: AppColors.spiritualGold.withValues(alpha: 0.85)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dhikr', style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600)),
                      Text(
                        'Now · ${now.name}',
                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Start ${now.name}',
                  child: Pressable(
                    onTap: () => _open(() => DhikrNav.openSession(context, now.id)),
                    pressedScale: 0.88,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.spiritualGold.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.spiritualGold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────── This week ───────────────────

class _WeeklyCard extends StatelessWidget {
  final Sunnah sunnah;
  final SunnahProgress progress;

  const _WeeklyCard({required this.sunnah, required this.progress});

  @override
  Widget build(BuildContext context) {
    final inPractice = progress.isInPractice(sunnah.id);
    final reference = SunnahFormat.shortReference(sunnah);

    return Pressable(
      onTap: () => showSunnahDetailSheet(context, sunnah),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.spiritualGold.withValues(alpha: 0.12),
              AppColors.spiritualGold.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.2), width: 0.5),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, if (current != null) current],
          ),
          child: Column(
            key: ValueKey(sunnah.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'This week',
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6)).copyWith(letterSpacing: 1),
                    ),
                  ),
                  Pressable(
                    onTap: () => context.read<SunnahBloc>().add(SkipWeeklySunnah()),
                    haptic: PressableHaptic.selection,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Colors.white.withValues(alpha: 0.55)),
                          const SizedBox(width: 4),
                          Text('Another', style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      sunnah.title,
                      style: AppTextStyles.bodyLarge(color: AppColors.spiritualGold, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SunnahFormat.description(sunnah),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.75)).copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                  if (inPractice)
                    SunnahCheck(
                      done: progress.isPracticedToday(sunnah.id),
                      onTap: () => context.read<SunnahBloc>().add(ToggleSunnahToday(sunnah.id)),
                    )
                  else
                    Pressable(
                      onTap: () => context.read<SunnahBloc>().add(ToggleSunnahPractice(sunnah.id)),
                      haptic: PressableHaptic.light,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 16, color: AppColors.spiritualGold),
                            const SizedBox(width: 4),
                            Text(
                              'Add to my practice',
                              style: AppTextStyles.small(color: AppColors.spiritualGold, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Your practice ───────────────────

class _PracticeList extends StatelessWidget {
  final List<Sunnah> sunnahs;
  final SunnahProgress progress;

  const _PracticeList({required this.sunnahs, required this.progress});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.04,
      edge: 0.06,
      edgeWidth: 0.5,
      child: Column(
        children: [
          for (var i = 0; i < sunnahs.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, indent: 16, color: Colors.white.withValues(alpha: 0.07)),
            _PracticeRow(sunnah: sunnahs[i], done: progress.isPracticedToday(sunnahs[i].id)),
          ],
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final Sunnah sunnah;
  final bool done;

  const _PracticeRow({required this.sunnah, required this.done});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => showSunnahDetailSheet(context, sunnah),
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: done ? 0.6 : 0.95),
                        weight: FontWeight.w500,
                      ),
                      child: Text(sunnah.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SunnahFormat.shortCategory(sunnah.category),
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ),
            SunnahCheck(
              done: done,
              semanticLabel: '${sunnah.title}, done today',
              onTap: () => context.read<SunnahBloc>().add(ToggleSunnahToday(sunnah.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeEmpty extends StatelessWidget {
  const _PracticeEmpty();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      radius: AppRadii.group,
      fill: 0.04,
      edge: 0.06,
      edgeWidth: 0.5,
      child: Text(
        'Choose a few sunnahs to bring back into your days. Open any one from the library and add it to your practice, then tick it off as you go.',
        style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)).copyWith(height: 1.5),
      ),
    );
  }
}

// ─────────────────── Library ───────────────────

class _LibraryRow extends StatelessWidget {
  final Sunnah sunnah;
  final bool showCategory;
  final bool inPractice;
  final bool doneToday;

  const _LibraryRow({
    required this.sunnah,
    required this.showCategory,
    required this.inPractice,
    required this.doneToday,
  });

  @override
  Widget build(BuildContext context) {
    final reference = SunnahFormat.shortReference(sunnah);
    final caption = showCategory
        ? [SunnahFormat.shortCategory(sunnah.category), if (reference.isNotEmpty) reference].join(' · ')
        : reference;

    return Pressable(
      onTap: () => showSunnahDetailSheet(context, sunnah),
      pressedScale: 0.975,
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        radius: 16,
        fill: 0.04,
        edge: 0.06,
        edgeWidth: 0.5,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sunnah.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.95), weight: FontWeight.w500),
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
                    ),
                  ],
                ],
              ),
            ),
            if (doneToday || inPractice) ...[
              const SizedBox(width: 10),
              Icon(
                doneToday ? Icons.check_circle_rounded : Icons.bookmark_rounded,
                size: 18,
                color: AppColors.spiritualGold.withValues(alpha: doneToday ? 0.9 : 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        haptic: PressableHaptic.selection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.spiritualGold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? AppColors.spiritualGold.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Text(label, style: AppTextStyles.small(color: color, weight: selected ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double horizontalPadding;
  final String? trailing;

  const _SectionLabel({required this.text, required this.horizontalPadding, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding + 4, 28, horizontalPadding + 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.tiny(color: AppColors.spiritualGold.withValues(alpha: 0.8))
                  .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
