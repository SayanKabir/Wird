import '../../../models/prayer_status.dart';
import '../../../models/prayer_log.dart';
import '../../../core/services/storage_service.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/repositories/sunnah_progress_repository.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../core/utils/islamic_day_utils.dart';
import '../../../models/prayer.dart';
import '../../../models/sunnah_progress.dart';
import '../../../models/tasbih.dart';
import '../../tasbih/bloc/tasbih_bloc.dart';
import '../../../core/repositories/quran_progress_repository.dart';
import '../../../models/quran_progress.dart';
import '../../../widgets/common/page_header.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/prayer_glyph.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/prayer_service.dart';
import '../../../widgets/common/app_route.dart';
import '../../../core/constants/radii.dart';
import '../../../widgets/common/count_up_text.dart';

// -----------------------------------------------------------------------------
// MAIN STATISTICS SCREEN
// -----------------------------------------------------------------------------

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// Numbers count up the first time Statistics is opened in a session,
  /// then simply show on later visits.
  static bool _countedUpThisSession = false;
  final bool _countUp = !_countedUpThisSession;

  final AchievementService _achievementService = AchievementService();
  final SunnahProgressRepository _sunnahProgressRepo = SunnahProgressRepository();
  final TasbihRepository _tasbihRepo = TasbihRepository();
  final QuranProgressRepository _quranProgressRepo = QuranProgressRepository();

  SunnahProgress? _sunnahProgress;
  QuranProgress? _quranProgress;
  List<Tasbih>? _tasbihs;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
    _countedUpThisSession = true;
  }

  Future<void> _loadExtraData() async {
    final progress = await _sunnahProgressRepo.getProgress();
    final quranProg = await _quranProgressRepo.getProgress();
    await _tasbihRepo.init();
    final tasbihs = await _tasbihRepo.getAllTasbihs();
    if (mounted) {
      setState(() {
        _sunnahProgress = progress;
        _quranProgress = quranProg;
        _tasbihs = tasbihs;
        _dataLoaded = true;
      });
    }
  }

  // ─── Shared pieces ───
  //
  // One card style for the whole page, and numbers in the same thin display
  // type as the home countdown, so Statistics reads like the rest of Wird
  // rather than a dashboard of identical tiles.

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  /// Icon and title along the top of a card, with an optional note at the end.
  Widget _cardTitle(IconData icon, String title, {String? note}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.spiritualGold.withValues(alpha: 0.85)),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.body(weight: FontWeight.w500)),
        const Spacer(),
        if (note != null) Text(note, style: AppTextStyles.small(color: Colors.white54)),
      ],
    );
  }

  /// A number over a small spaced label.
  Widget _figure(String value, String label) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: CountUpText(value, animate: _countUp, style: AppTextStyles.display(size: 30, height: 1.0)),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          style: AppTextStyles.tiny(color: Colors.white54).copyWith(fontSize: 10, letterSpacing: 1.4),
        ),
      ],
    );
  }

  /// Figures side by side, split by hairlines.
  Widget _figures(List<(String, String)> items) {
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white.withValues(alpha: 0.14),
              ),
            Expanded(child: _figure(items[i].$1, items[i].$2)),
          ],
        ],
      ),
    );
  }

  /// A titled card of figures, for Sunnah, Quran and Dhikr.
  Widget _statCard({required IconData icon, required String title, required List<(String, String)> figures}) {
    return _card(
      child: Column(
        children: [
          _cardTitle(icon, title),
          const SizedBox(height: 20),
          _figures(figures),
        ],
      ),
    );
  }

  Widget _padded(Widget child, {double top = 14}) => SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.fromLTRB(24, top, 24, 0), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final stats = _achievementService.getStatistics();
    final achievements = _achievementService.calculateAchievements();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.spiritualGold,
          onRefresh: _loadExtraData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                  child: const PageHeader(overline: "INSIGHTS", title: "Statistics"),
                ),
              ),

              // Prayer: the streak, and the week prayer by prayer.
              _padded(_prayerHero(stats)),
              _padded(_buildAchievementsBanner(context, achievements)),
              _padded(_byPrayerCard(stats['prayerStreaks'] as Map<String, int>)),

              if (_dataLoaded) ..._sunnahSlivers(),
              if (_dataLoaded) ..._quranSlivers(),
              if (_dataLoaded) ..._tasbihSlivers(),

              ..._eventSlivers(),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Prayer ───

  Widget _prayerHero(Map<String, dynamic> stats) {
    final streak = stats['currentStreak'] as int;
    Widget side(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CountUpText(value, animate: _countUp, style: AppTextStyles.display(size: 22, height: 1.1)),
            Text(label, style: AppTextStyles.tiny(color: Colors.white54)),
          ],
        );

    return _card(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRAYER STREAK',
                      style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                          .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUpText('$streak', animate: _countUp, style: AppTextStyles.display(size: 64, height: 1.0)),
                        const SizedBox(width: 8),
                        Text(streak == 1 ? 'day' : 'days', style: AppTextStyles.body(color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  side('${stats['longestStreak']}', 'best streak'),
                  const SizedBox(height: 10),
                  side('${stats['weekPercentage']}%', 'on time this week'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          _WeekRibbon(logs: StorageService().getRecentPrayerLogs(7)),
        ],
      ),
    );
  }

  /// Each prayer's streak against the longest, with its glyph in colour.
  Widget _byPrayerCard(Map<String, int> streaks) {
    final longest = fardhPrayers.fold<int>(7, (m, p) => math.max(m, streaks[p.name] ?? 0));
    return _card(
      child: Column(
        children: [
          _cardTitle(Icons.timeline_rounded, 'By prayer', note: 'day streaks'),
          const SizedBox(height: 8),
          for (final prayer in fardhPrayers) _prayerStreakRow(prayer, streaks[prayer.name] ?? 0, longest),
        ],
      ),
    );
  }

  Widget _prayerStreakRow(Prayer prayer, int streak, int longest) {
    final accent = _prayerAccent(prayer);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [for (final c in prayerSky(prayer)) c.withValues(alpha: 0.7)],
              ),
            ),
            child: PrayerGlyph.colored(prayer: prayer, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prayer.displayName, style: AppTextStyles.body(weight: FontWeight.w500)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Container(height: 4, color: Colors.white.withValues(alpha: 0.08)),
                      FractionallySizedBox(
                        widthFactor: (streak / longest).clamp(0.0, 1.0),
                        child: Container(height: 4, color: accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 36,
            child: Text(
              '$streak',
              textAlign: TextAlign.right,
              style: AppTextStyles.display(size: 24, height: 1.0, color: streak > 0 ? Colors.white : Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sunnah ───
  List<Widget> _sunnahSlivers() {
    final p = _sunnahProgress;
    if (p == null) return [];
    return [
      _padded(_statCard(
        icon: Icons.auto_stories_rounded,
        title: 'Sunnah',
        figures: [
          ('${p.liveStreak()}', 'streak'),
          ('${p.longestStreak}', 'best'),
          ('${p.uniqueSunnahsPracticed}', 'kept'),
          ('${p.totalPracticeActions}', 'times'),
        ],
      )),
      if (p.practiceCountsBySunnah.isNotEmpty) _padded(_buildTopSunnahsList(p), top: 10),
    ];
  }

  // ─── Quran ───
  List<Widget> _quranSlivers() {
    final q = _quranProgress;
    if (q == null) return [];
    return [
      _padded(_statCard(
        icon: Icons.menu_book_rounded,
        title: 'Quran',
        figures: [
          (_formatCount(q.totalVersesRead), 'verses'),
          ('${q.daysRead}', 'days'),
          ('${q.currentStreak}', 'streak'),
          ('${q.longestStreak}', 'best'),
        ],
      )),
    ];
  }

  // ─── Dhikr ───
  List<Widget> _tasbihSlivers() {
    // Prefer the live counters so counting elsewhere shows up here at once.
    final live = context.watch<TasbihBloc>().state;
    final tasbihs = live is TasbihLoaded ? live.tasbihs : _tasbihs;
    if (tasbihs == null || tasbihs.isEmpty) return [];

    final totalLifetime = tasbihs.fold<int>(0, (sum, t) => sum + t.totalCount);
    final totalToday = tasbihs.fold<int>(0, (sum, t) => sum + t.todayCount());
    final visible = TasbihRepository.visibleCounters(tasbihs);
    final mostRecited = (visible.isEmpty ? tasbihs : visible).reduce((a, b) => a.totalCount > b.totalCount ? a : b);

    return [
      _padded(_statCard(
        icon: Icons.fingerprint_rounded,
        title: 'Dhikr',
        figures: [
          (_formatCount(totalLifetime), 'all time'),
          (_formatCount(totalToday), 'today'),
        ],
      )),
      if (mostRecited.totalCount > 0) _padded(_buildMostRecitedCard(mostRecited), top: 10),
    ];
  }

  // ─── Upcoming event sliver ───
  List<Widget> _eventSlivers() {
    final next = IslamicDayUtils.nextImportantEvent(DateTime.now());
    if (next == null) return [];

    return [_padded(_buildEventCard(next))];
  }

  // --- Components for Statistics Screen ---

  Widget _buildAchievementsBanner(BuildContext context, List<Achievement> achievements) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return Pressable(
      pressedScale: 0.98,
      haptic: PressableHaptic.none,
      onTap: () {
        HapticService().light();
        Navigator.push(
            context,
            AppRoute(builder: (context) => AchievementsScreen(achievements: achievements))
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.spiritualGold.withValues(alpha: 0.15),
                AppColors.spiritualGold.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.spiritualGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.spiritualGold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Achievements",
                      style: AppTextStyles.h3(color: AppColors.spiritualGold),
                    ),
                    Text(
                      "$unlockedCount / $totalCount unlocked",
                      style: AppTextStyles.small(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── Sunnah Widgets ───────────────

  Widget _buildTopSunnahsList(SunnahProgress p) {
    final sorted = p.practiceCountsBySunnah.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Most Kept",
              style: AppTextStyles.small(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            ...top.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final sunnahId = entry.value.key;
              final count = entry.value.value;
              final name = _cleanSunnahId(sunnahId);
              final isLast = rank == top.length;

              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? AppColors.spiritualGold.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$rank",
                        style: AppTextStyles.tiny(
                          color: rank <= 3 ? AppColors.spiritualGold : Colors.white30,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.85)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.spiritualGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$count×",
                        style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────── Tasbih Widgets ───────────────

  Widget _buildMostRecitedCard(Tasbih tasbih) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.spiritualGold.withValues(alpha: 0.15),
              AppColors.spiritualGold.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.spiritualGold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded, color: AppColors.spiritualGold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Most Recited", style: AppTextStyles.tiny(color: Colors.white54)),
                  Text(
                    tasbih.name,
                    style: AppTextStyles.h3(color: AppColors.spiritualGold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.spiritualGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                _formatCount(tasbih.totalCount),
                style: AppTextStyles.small(color: AppColors.spiritualGold, weight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── Event Widget ───────────────

  Widget _buildEventCard(NextEventInfo next) {
    final accent = IslamicDayUtils.accentColor(next.event.type);
    final icon = IslamicDayUtils.iconForType(next.event.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.15),
              accent.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    next.event.title,
                    style: AppTextStyles.h3(color: accent),
                  ),
                  Text(
                    next.event.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tiny(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    "${next.daysUntil}",
                    style: AppTextStyles.h2(color: accent),
                  ),
                  Text(
                    "days",
                    style: AppTextStyles.tiny(color: accent.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── Helpers ───────────────

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  String _cleanSunnahId(String id) {
    try {
      final match = context
          .read<SunnahRepository>()
          .getAllSunnahsSync()
          .where((s) => s.id == id);
      if (match.isNotEmpty) return match.first.title;
    } catch (_) {
      // No repository in scope; fall back to prettifying the id.
    }
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// -----------------------------------------------------------------------------
// ACHIEVEMENTS SCREEN & WIDGETS
// -----------------------------------------------------------------------------

class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;
  
  const AchievementsScreen({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    // This is a pushed route, so it sits above the celestial background rather
    // than inside it and has to paint its own. It previously used a one-off
    // navy-to-black gradient that appeared nowhere else in the app, which is
    // why arriving here felt like leaving it. Use the same palette the other
    // pushed full-screen route (the surah reader) uses.
    final gradientColors = AppColors.getGradientForPeriod(PrayerPeriod.tahajjud);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header
              SliverToBoxAdapter(
                child: Padding(
                  // Matches the Statistics tab this screen is opened from.
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        overline: "MILESTONES",
                        title: "Achievements",
                        overlineColor: AppColors.spiritualGold,
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${unlocked.length} of ${achievements.length} Unlocked",
                        style: AppTextStyles.body(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Unlocked Grid
              if (unlocked.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _AchievementCard(item: unlocked[index]),
                      childCount: unlocked.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],

              // 3. Locked Header
              if (locked.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Text(
                      "LOCKED",
                      style: AppTextStyles.tiny(color: Colors.white30).copyWith(letterSpacing: 2),
                    ),
                  ),
                ),

              // 4. Locked List
              if (locked.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LockedAchievementTile(item: locked[index]),
                      ),
                      childCount: locked.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement item;

  const _AchievementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.spiritualGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.3)),
          // No glow: these were the only two boxShadows in the app, which is
          // part of why this screen read as foreign. The gold fill and border
          // already mark a badge as unlocked without them.
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.spiritualGold,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.black, size: 20),
            ),
            const Spacer(),
            Text(
              item.title,
              style: AppTextStyles.h3().copyWith(height: 1.2),
            ),
            const SizedBox(height: 4),
            if (item.unlockedDate != null)
              Text(
                DateFormat('MMM d, y').format(item.unlockedDate!),
                style: AppTextStyles.tiny(color: AppColors.spiritualGold),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedAchievementTile extends StatelessWidget {
  final Achievement item;

  const _LockedAchievementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Colors.white30, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.body(color: Colors.white60),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: AppTextStyles.tiny(color: Colors.white30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.progress > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.spiritualGold.withValues(alpha: 0.6),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.progressText,
                    style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Each fard prayer's own accent, used for the week's dots and streak bars.
Color _prayerAccent(Prayer prayer) => switch (prayer) {
      Prayer.fajr => AppColors.fajrAccent,
      Prayer.dhuhr => AppColors.dhuhrAccent,
      Prayer.asr => AppColors.asrAccent,
      // Sunset rose rather than Maghrib's red accent, which reads as "missed".
      Prayer.maghrib => const Color(0xFFE55D87),
      _ => const Color(0xFF9D8CFF),
    };

/// The last seven days, one column each, a dot per prayer: lit in the
/// prayer's colour when prayed (dimmer if late), a red ring when missed,
/// a faint ring when not logged.
class _WeekRibbon extends StatelessWidget {
  final List<PrayerLog> logs;

  const _WeekRibbon({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = {for (final l in logs) DateTime(l.date.year, l.date.month, l.date.day): l};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 6; i >= 0; i--)
          _day(today.subtract(Duration(days: i)), byDay, isToday: i == 0),
      ],
    );
  }

  Widget _day(DateTime day, Map<DateTime, PrayerLog> byDay, {required bool isToday}) {
    final log = byDay[day];
    return Container(
      width: 34,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? Colors.white.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('E').format(day).substring(0, 1),
            style: AppTextStyles.tiny(color: isToday ? Colors.white : Colors.white54)
                .copyWith(fontWeight: isToday ? FontWeight.w700 : FontWeight.w500),
          ),
          const SizedBox(height: 8),
          for (final prayer in fardhPrayers) ...[
            _dot(prayer, log?.entries[prayer]?.status),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _dot(Prayer prayer, PrayerStatus? status) {
    const size = 9.0;
    final accent = _prayerAccent(prayer);
    if (status != null && status.isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: status == PrayerStatus.onTime ? accent : accent.withValues(alpha: 0.45),
          boxShadow: status == PrayerStatus.onTime
              ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 5)]
              : null,
        ),
      );
    }
    final missed = status == PrayerStatus.missed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: missed ? AppColors.statusMissed.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
    );
  }
}
