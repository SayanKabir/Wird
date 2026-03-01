import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/repositories/sunnah_progress_repository.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../core/utils/islamic_day_utils.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_status.dart';
import '../../../models/sunnah_progress.dart';
import '../../../models/tasbih.dart';
import '../../../core/repositories/quran_progress_repository.dart';
import '../../../models/quran_progress.dart';

// -----------------------------------------------------------------------------
// MAIN STATISTICS SCREEN
// -----------------------------------------------------------------------------

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StorageService _storageService = StorageService();
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

  // ─── Shared section header ───
  Widget _sectionHeader(String label, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.tiny(color: accent)
                .copyWith(letterSpacing: 2.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── Thin divider between major sections ───
  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Container(
        height: 0.5,
        color: Colors.white.withOpacity(0.06),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _achievementService.getStatistics();
    final achievements = _achievementService.calculateAchievements();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.activeGlow,
          onRefresh: _loadExtraData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
            // ─── Page Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INSIGHTS",
                      style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4))
                          .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Statistics", style: AppTextStyles.h1()),
                  ],
                ),
              ),
            ),

            // ─── Prayer Hero Streak ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeroStreakCard(stats['currentStreak'] as int),
              ),
            ),

            // ─── Prayer Key Metrics ───
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  _buildGlassMetricCard(
                    title: "Best Streak",
                    value: "${stats['longestStreak']}",
                    unit: "DAYS",
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.spiritualGold,
                  ),
                  _buildGlassMetricCard(
                    title: "This Week",
                    value: "${stats['weekPercentage']}%",
                    unit: "COMPLETION",
                    icon: Icons.pie_chart_rounded,
                    color: AppColors.activeGlow,
                  ),
                ],
              ),
            ),

            // ─── Overview Summary ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                child: _buildOverviewCard(
                  stats['weekOnTime'] as int,
                  stats['weekTotal'] as int,
                ),
              ),
            ),

            // ─── Achievements Banner ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildAchievementsBanner(context, achievements),
              ),
            ),

            // ─── Divider ───
            SliverToBoxAdapter(child: _sectionDivider()),

            // ─── By Prayer Section ───
            SliverToBoxAdapter(child: _sectionHeader("BY PRAYER", AppColors.streakFire)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prayer = fardhPrayers[index];
                    final streak = (stats['prayerStreaks'] as Map<String, int>)[prayer.name] ?? 0;
                    return _buildPrayerStreakRow(prayer, streak, index == fardhPrayers.length - 1);
                  },
                  childCount: fardhPrayers.length,
                ),
              ),
            ),

            // Best Prayer Card
            if (stats['bestPrayer'] != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: _buildBestPrayerCard(
                    stats['bestPrayer'] as String,
                    stats['bestPrayerStreak'] as int,
                  ),
                ),
              ),

            // ─── Divider ───
            SliverToBoxAdapter(child: _sectionDivider()),

            // ─── Sunnah Progress Section ───
            if (_dataLoaded) ..._sunnahSlivers(),

            // ─── Divider ───
            if (_dataLoaded)
              SliverToBoxAdapter(child: _sectionDivider()),

            // ─── Quran Reading Section ───
            if (_dataLoaded) ..._quranSlivers(),

            // ─── Divider ───
            if (_dataLoaded)
              SliverToBoxAdapter(child: _sectionDivider()),

            // ─── Tasbih & Dhikr Section ───
            if (_dataLoaded) ..._tasbihSlivers(),

            // ─── Divider ───
            if (_dataLoaded)
              SliverToBoxAdapter(child: _sectionDivider()),

            // ─── Upcoming Islamic Events ───
            ..._eventSlivers(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
      ),
    );
  }

  // ─── Sunnah section slivers ───
  List<Widget> _sunnahSlivers() {
    final p = _sunnahProgress;
    if (p == null) return [];

    return [
      SliverToBoxAdapter(child: _sectionHeader("SUNNAH PROGRESS", const Color(0xFF73D38A))),

      // Streak + Level hero
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildSunnahHero(p),
        ),
      ),

      // Metrics grid
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildGlassMetricCard(
              title: "Unique Sunnahs",
              value: "${p.uniqueSunnahsPracticed}",
              unit: "PRACTICED",
              icon: Icons.explore_rounded,
              color: const Color(0xFF73D38A),
            ),
            _buildGlassMetricCard(
              title: "Total Actions",
              value: "${p.totalPracticeActions}",
              unit: "PRACTICES",
              icon: Icons.trending_up_rounded,
              color: AppColors.activeGlow,
            ),
            _buildGlassMetricCard(
              title: "Best Streak",
              value: "${p.longestStreak}",
              unit: "DAYS",
              icon: Icons.emoji_events_rounded,
              color: AppColors.spiritualGold,
            ),
            _buildGlassMetricCard(
              title: "Badges",
              value: "${p.unlockedBadges.length}",
              unit: "UNLOCKED",
              icon: Icons.military_tech_rounded,
              color: const Color(0xFFE0A8FF),
            ),
          ],
        ),
      ),

      // Top Sunnahs list
      if (p.practiceCountsBySunnah.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: _buildTopSunnahsList(p),
          ),
        ),
    ];
  }

  // ─── Quran section slivers ───
  List<Widget> _quranSlivers() {
    final q = _quranProgress;
    if (q == null) return [];

    const quranAccent = Color(0xFF64B5F6);

    return [
      SliverToBoxAdapter(child: _sectionHeader("QURAN READING", quranAccent)),

      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildGlassMetricCard(
              title: "Total Read",
              value: "${q.totalVersesRead}",
              unit: "VERSES",
              icon: Icons.menu_book_rounded,
              color: quranAccent,
            ),
            _buildGlassMetricCard(
              title: "Days Read",
              value: "${q.daysRead}",
              unit: "DAYS",
              icon: Icons.event_available_rounded,
              color: const Color(0xFF9CCC65),
            ),
            _buildGlassMetricCard(
              title: "Current Streak",
              value: "${q.currentStreak}",
              unit: "DAYS",
              icon: Icons.local_fire_department_rounded,
              color: AppColors.streakFire,
            ),
            _buildGlassMetricCard(
              title: "Best Streak",
              value: "${q.longestStreak}",
              unit: "DAYS",
              icon: Icons.emoji_events_rounded,
              color: AppColors.spiritualGold,
            ),
          ],
        ),
      ),
    ];
  }

  // ─── Tasbih section slivers ───
  List<Widget> _tasbihSlivers() {
    final tasbihs = _tasbihs;
    if (tasbihs == null || tasbihs.isEmpty) return [];

    final totalLifetime = tasbihs.fold<int>(0, (sum, t) => sum + t.totalCount);
    final mostRecited = tasbihs.reduce((a, b) => a.totalCount > b.totalCount ? a : b);

    return [
      SliverToBoxAdapter(child: _sectionHeader("TASBIH & DHIKR", AppColors.activeGlow)),

      // Total lifetime + active counters
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildGlassMetricCard(
              title: "Lifetime Dhikr",
              value: _formatCount(totalLifetime),
              unit: "BEADS",
              icon: Icons.all_inclusive_rounded,
              color: AppColors.activeGlow,
            ),
            _buildGlassMetricCard(
              title: "Active Counters",
              value: "${tasbihs.length}",
              unit: "TASBIHS",
              icon: Icons.grid_view_rounded,
              color: const Color(0xFF73D38A),
            ),
          ],
        ),
      ),

      // Most recited card
      if (mostRecited.totalCount > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: _buildMostRecitedCard(mostRecited),
          ),
        ),
    ];
  }

  // ─── Upcoming event sliver ───
  List<Widget> _eventSlivers() {
    final next = IslamicDayUtils.nextImportantEvent(DateTime.now());
    if (next == null) return [];

    return [
      SliverToBoxAdapter(child: _sectionHeader("UPCOMING", const Color(0xFFFFD580))),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildEventCard(next),
        ),
      ),
    ];
  }

  // --- Components for Statistics Screen ---

  Widget _buildHeroStreakCard(int streak) {
    final bool isActive = streak > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.streakFire.withOpacity(0.15),
                AppColors.streakFire.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.streakFire.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.streakFire.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.streakFire,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Streak",
                      style: AppTextStyles.tiny(color: Colors.white54),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$streak",
                          style: AppTextStyles.h2(color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          streak == 1 ? "Day" : "Days",
                          style: AppTextStyles.body(
                              color: AppColors.streakFire.withOpacity(0.9)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.streakFire.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.streakFire.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Active",
                    style: AppTextStyles.small(color: AppColors.streakFire, weight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          // Reduced padding to ensure fit
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Added FittedBox to scale text if number is huge
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: AppTextStyles.h2().copyWith(height: 1.0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTextStyles.tiny(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsBanner(BuildContext context, List<Achievement> achievements) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AchievementsScreen(achievements: achievements))
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.spiritualGold.withOpacity(0.15),
                  AppColors.spiritualGold.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.spiritualGold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.spiritualGold.withOpacity(0.2),
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
      ),
    );
  }

  Widget _buildPrayerStreakRow(Prayer prayer, int streak, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Text(prayer.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prayer.displayName, style: AppTextStyles.bodyLarge()),
                Text(
                  streak > 0 ? "$streak day streak" : "No streak yet",
                  style: AppTextStyles.tiny(
                      color: streak > 0 ? AppColors.spiritualGold : Colors.white30
                  ),
                ),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.streakFire.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.streakFire.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.streakFire),
                  const SizedBox(width: 4),
                  Text(
                      "$streak",
                      style: AppTextStyles.small(color: AppColors.streakFire, weight: FontWeight.bold)
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(int onTime, int total) {
    final missed = total - onTime;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem("ON TIME", "$onTime", AppColors.statusOnTime),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildOverviewItem("TOTAL", "$total", Colors.white),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildOverviewItem("MISSED", "$missed", AppColors.statusMissed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.tiny(color: Colors.white30)),
      ],
    );
  }

  Widget _buildBestPrayerCard(String prayerName, int streak) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.activeGlow.withOpacity(0.15),
                AppColors.activeGlow.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.activeGlow.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.activeGlow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.activeGlow),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Best Prayer",
                      style: AppTextStyles.tiny(color: Colors.white54),
                    ),
                    Text(
                      prayerName,
                      style: AppTextStyles.h3(color: AppColors.activeGlow),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.streakFire.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.streakFire.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.streakFire),
                    const SizedBox(width: 4),
                    Text(
                      "$streak days",
                      style: AppTextStyles.small(color: AppColors.streakFire, weight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── Sunnah Widgets ───────────────

  Widget _buildSunnahHero(SunnahProgress p) {
    const sunnahAccent = Color(0xFF73D38A);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                sunnahAccent.withOpacity(0.15),
                sunnahAccent.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sunnahAccent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sunnahAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: sunnahAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Level ${p.level}",
                      style: AppTextStyles.h2(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${p.totalPoints} pts  •  ${p.currentStreak} day streak",
                      style: AppTextStyles.tiny(color: sunnahAccent),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  "Rank",
                  style: AppTextStyles.small(color: Colors.white70, weight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSunnahsList(SunnahProgress p) {
    final sorted = p.practiceCountsBySunnah.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Most Practiced",
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
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank <= 3
                              ? AppColors.spiritualGold.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
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
                          style: AppTextStyles.body(color: Colors.white.withOpacity(0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF73D38A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$count×",
                          style: AppTextStyles.tiny(color: const Color(0xFF73D38A))
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
      ),
    );
  }

  // ─────────────── Tasbih Widgets ───────────────

  Widget _buildMostRecitedCard(Tasbih tasbih) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.activeGlow.withOpacity(0.15),
                AppColors.activeGlow.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.activeGlow.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.activeGlow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text("📿", style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Most Recited", style: AppTextStyles.tiny(color: Colors.white54)),
                    Text(
                      tasbih.name,
                      style: AppTextStyles.h3(color: AppColors.activeGlow),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.activeGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.activeGlow.withOpacity(0.3)),
                ),
                child: Text(
                  _formatCount(tasbih.totalCount),
                  style: AppTextStyles.small(color: AppColors.activeGlow, weight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.15),
                accent.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
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
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      "${next.daysUntil}",
                      style: AppTextStyles.h2(color: accent),
                    ),
                    Text(
                      "days",
                      style: AppTextStyles.tiny(color: accent.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    // Convert snake_case ID to Title Case
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

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent/stack
      // Using CelestialBackground in Home, but here we likely rely on parent Scaffold's background
      // If navigated to directly, ensure root scaffold has background.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Colors.black], // Fallback background
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "MILESTONES",
                        style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                            .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Achievements",
                        style: AppTextStyles.h1(),
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.spiritualGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.spiritualGold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.spiritualGold.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.spiritualGold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.spiritualGold.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
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
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.spiritualGold.withOpacity(0.6),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.progressText,
                      style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.4)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}