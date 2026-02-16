import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/sunnah.dart';
import '../../../models/sunnah_progress.dart';
import '../../../widgets/common/glass_container.dart';
import '../../tasbih/screens/tasbih_screen.dart';
import '../bloc/sunnah_bloc.dart';
import '../widgets/sunnah_category_block.dart';

import '../widgets/sunnah_other_header.dart';
import '../widgets/sunnah_page_header.dart';
import '../widgets/sunnah_tile.dart';
import '../widgets/sunnah_weekly_card.dart';

class SunnahScreen extends StatefulWidget {
  const SunnahScreen({super.key});

  @override
  State<SunnahScreen> createState() => _SunnahScreenState();
}

class _SunnahScreenState extends State<SunnahScreen> {
  // --- State Variables ---
  final Set<String> _expandedCategories = <String>{};

  // Filter States
  final Set<SunnahFrequency> _selectedFrequencies = <SunnahFrequency>{};
  final Set<SunnahDifficulty> _selectedDifficulties = <SunnahDifficulty>{};
  final Set<String> _selectedCategories = <String>{};
  bool _expandAll = false;
  bool _tasbihOnly = false;

  // Caching
  _SunnahViewCache? _viewCache;
  List<Sunnah>? _cachedSunnahsRef;
  String? _cachedWeeklyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Using extendBodyBehindAppBar if you have one, otherwise safe area is fine
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SunnahBloc, SunnahState>(
          builder: (context, state) {
            if (state is SunnahLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (state is SunnahError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load Sunnahs',
                        style: AppTextStyles.h3(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: AppTextStyles.body(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SunnahLoaded) {
              return _buildLoadedState(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, SunnahLoaded state) {
    final viewCache = _getOrBuildViewCache(state);
    final progress = state.progress;
    final filteredSunnahs = _applyFilters(state.sunnahs, viewCache);
    final weeklySunnah = state.weeklySunnah;

    // Determine if we show the weekly card (only if it matches filters)
    final showWeeklySunnah = weeklySunnah != null &&
        filteredSunnahs.any((sunnah) => sunnah.id == weeklySunnah.id);

    late final List<Sunnah> remaining;
    late final Map<String, List<Sunnah>> grouped;
    late final List<MapEntry<String, List<Sunnah>>> groupedEntries;

    // Optimization: If no filters active, use cached groups
    if (!_hasActiveFilters && showWeeklySunnah) {
      remaining = viewCache.remaining;
      grouped = viewCache.grouped;
      groupedEntries = viewCache.groupedEntries;
    } else {
      // Re-group based on filtered results
      remaining = filteredSunnahs
          .where((sunnah) => sunnah.id != weeklySunnah?.id)
          .toList(growable: false);
      grouped = _groupSunnahsByCategory(remaining);
      groupedEntries = grouped.entries.toList(growable: false);
    }

    // Clean up expanded states for categories that no longer exist due to filtering
    _expandedCategories.removeWhere((category) => !grouped.containsKey(category));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Header Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SunnahPageHeader(
                  heading: 'SUNNAH',
                  subheading: 'Revive the Tradition',
                ),
                const SizedBox(height: 12),
                // SunnahGamificationStrip(
                //   level: progress.level,
                //   totalPoints: progress.totalPoints,
                //   levelProgress: progress.levelProgress,
                //   streak: progress.currentStreak,
                //   practicedTodayCount: _practicedTodayCount(progress),
                //   practicedUniqueCount: progress.uniqueSunnahsPracticed,
                //   totalSunnahCount: state.sunnahs.length,
                //   badges: progress.unlockedBadges,
                // ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // 2. Weekly Sunnah Card
        if (showWeeklySunnah)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverToBoxAdapter(
              child: SunnahWeeklyCard(
                sunnah: weeklySunnah,
                weekLabel: _weekLabel(),
                isDhikrLinked: _tasbihLaunchForSunnah(weeklySunnah) != null,
                categoryIcon: _iconForCategory(weeklySunnah.category),
                difficultyLabel: _difficultyLabel(weeklySunnah.difficulty),
                frequencyLabel: _frequencyLabel(weeklySunnah.frequency),
                isPracticedToday: progress.isPracticedToday(weeklySunnah.id),
                onPracticeTap: () {
                  _markSunnahPracticed(context, weeklySunnah);
                },
                onReadDetailsTap: () => _openSunnahSheet(context, weeklySunnah),
                onOpenTasbihTap: () => _openTasbih(context, sunnah: weeklySunnah),
                onSkipTap: () => context.read<SunnahBloc>().add(SkipWeeklySunnah()),
              ),
            ),
          ),

        // 3. List Header & Filters
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          sliver: SliverToBoxAdapter(
            child: SunnahOtherHeader(
              count: remaining.length,
              expandAll: _expandAll,
              activeFilterCount: _activeFilterCount,
              activeFilterTags: _activeFilterTags(),
              onToggleExpandAll: () => _toggleExpandAll(grouped),
              onOpenFilters: () => _openFilterSheet(context, viewCache),
              onRemoveTag: _handleRemoveTag, // NEW CALLBACK
            ),
          ),
        ),

        // 4. Content or Empty State
        if (remaining.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: GlassContainer(
                opacity: 0.05,
                blur: 10,
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.filter_list_off_rounded, color: Colors.white.withValues(alpha: 0.4), size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'No Sunnahs match your filters.',
                      style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear all filters'),
                    )
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = groupedEntries[index];
                final category = entry.key;
                final sunnahs = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RepaintBoundary(
                    child: SunnahCategoryBlock(
                      category: category,
                      sunnahs: sunnahs,
                      isExpanded: _isCategoryExpanded(category),
                      typeSummary: _sectionTypeSummary(sunnahs),
                      icon: _iconForCategory(category),
                      onToggle: () => _toggleCategory(category),
                      tileBuilder: (sunnah) {
                        return SunnahTile(
                          sunnah: sunnah,
                          subtitle: _tileSubtitle(sunnah),
                          isDhikrLinked: _tasbihLaunchForSunnah(sunnah) != null,
                          isPracticedToday: progress.isPracticedToday(sunnah.id),
                          difficultyColor: _difficultyColor(sunnah.difficulty),
                          difficultyLabel: _difficultyLabel(sunnah.difficulty),
                          frequencyLabel: _frequencyLabel(sunnah.frequency),
                          shortReference: _shortReference(sunnah.reference['hadith']),
                          categoryIcon: _iconForCategory(sunnah.category),
                          onTap: () => _openSunnahSheet(context, sunnah),
                        );
                      },
                    ),
                  ),
                );
              }, childCount: groupedEntries.length),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  // --- Logic for Filters & Tags ---

  void _handleRemoveTag(String tag) {
    setState(() {
      // 1. Check Frequencies
      for (final freq in SunnahFrequency.values) {
        if (_frequencyLabel(freq) == tag) {
          _selectedFrequencies.remove(freq);
          return;
        }
      }

      // 2. Check Difficulties
      for (final diff in SunnahDifficulty.values) {
        if (_difficultyLabel(diff) == tag) {
          _selectedDifficulties.remove(diff);
          return;
        }
      }

      // 3. Check Tasbih
      if (tag == 'Tasbih-linked') {
        _tasbihOnly = false;
        return;
      }

      // 4. Check Categories (Default fallback)
      if (_selectedCategories.contains(tag)) {
        _selectedCategories.remove(tag);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFrequencies.clear();
      _selectedDifficulties.clear();
      _selectedCategories.clear();
      _tasbihOnly = false;
    });
  }

  // ... (Existing _getOrBuildViewCache logic remains the same) ...
  _SunnahViewCache _getOrBuildViewCache(SunnahLoaded state) {
    final weeklyId = state.weeklySunnah?.id;
    if (_viewCache != null &&
        identical(_cachedSunnahsRef, state.sunnahs) &&
        _cachedWeeklyId == weeklyId) {
      return _viewCache!;
    }

    final remaining = state.sunnahs
        .where((sunnah) => sunnah.id != state.weeklySunnah?.id)
        .toList(growable: false);
    final grouped = _groupSunnahsByCategory(remaining);
    final groupedEntries = grouped.entries.toList(growable: false);
    final availableCategories = groupedEntries.map((entry) => entry.key).toList(growable: false);
    final tasbihLaunchById = <String, _TasbihLaunch?>{
      for (final sunnah in state.sunnahs)
        sunnah.id: sunnah.tasbihId != null
            ? _TasbihLaunch(initialTasbihId: sunnah.tasbihId!, initialQuery: sunnah.title)
            : null,
    };

    final next = _SunnahViewCache(
      remaining: remaining,
      grouped: grouped,
      groupedEntries: groupedEntries,
      availableCategories: availableCategories,
      tasbihLaunchById: tasbihLaunchById,
    );
    _viewCache = next;
    _cachedSunnahsRef = state.sunnahs;
    _cachedWeeklyId = weeklyId;
    return next;
  }

  bool get _hasActiveFilters =>
      _selectedFrequencies.isNotEmpty ||
          _selectedDifficulties.isNotEmpty ||
          _selectedCategories.isNotEmpty ||
          _tasbihOnly;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedFrequencies.isNotEmpty) count++;
    if (_selectedDifficulties.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_tasbihOnly) count++;
    return count;
  }

  List<String> _activeFilterTags() {
    final tags = <String>[];
    tags.addAll(_selectedFrequencies.map(_frequencyLabel));
    tags.addAll(_selectedDifficulties.map(_difficultyLabel));
    tags.addAll(_selectedCategories);
    if (_tasbihOnly) tags.add('Tasbih-linked');
    return tags;
  }

  int _practicedTodayCount(SunnahProgress progress) {
    final today = _dateKey(DateTime.now());
    return progress.lastPracticedDayBySunnah.values
        .where((date) => date == today)
        .length;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _markSunnahPracticed(BuildContext context, Sunnah sunnah) {
    final currentState = context.read<SunnahBloc>().state;
    var alreadyPracticed = false;
    if (currentState is SunnahLoaded) {
      alreadyPracticed = currentState.progress.isPracticedToday(sunnah.id);
    }

    context.read<SunnahBloc>().add(MarkSunnahPracticed(sunnahId: sunnah.id));
    _showAppSnackBar(
      context,
      message: alreadyPracticed
          ? '${sunnah.title} already tracked today.'
          : '${sunnah.title} tracked. Points added.',
      icon: alreadyPracticed
          ? Icons.info_outline_rounded
          : Icons.local_fire_department_rounded,
    );
  }

  List<Sunnah> _applyFilters(List<Sunnah> all, _SunnahViewCache viewCache) {
    if (!_hasActiveFilters) return all;
    return all.where((sunnah) => _matchesFilters(sunnah, viewCache)).toList(growable: false);
  }

  bool _matchesFilters(Sunnah sunnah, _SunnahViewCache viewCache) {
    if (_selectedFrequencies.isNotEmpty && !_selectedFrequencies.contains(sunnah.frequency)) return false;
    if (_selectedDifficulties.isNotEmpty && !_selectedDifficulties.contains(sunnah.difficulty)) return false;
    if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(sunnah.category)) return false;
    if (_tasbihOnly && viewCache.tasbihLaunchById[sunnah.id] == null) return false;
    return true;
  }

  // --- UI: Filter Sheet ---

  Future<void> _openFilterSheet(BuildContext context, _SunnahViewCache viewCache) async {
    // Clone state for the modal
    final tempFrequencies = Set<SunnahFrequency>.from(_selectedFrequencies);
    final tempDifficulties = Set<SunnahDifficulty>.from(_selectedDifficulties);
    final tempCategories = Set<String>.from(_selectedCategories);
    var tempTasbihOnly = _tasbihOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6), // Modern dark overlay
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildGlassSheet(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            )
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter Sunnahs', style: AppTextStyles.h2(color: Colors.white)),
                          if (tempFrequencies.isNotEmpty || tempDifficulties.isNotEmpty || tempCategories.isNotEmpty || tempTasbihOnly)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempFrequencies.clear();
                                  tempDifficulties.clear();
                                  tempCategories.clear();
                                  tempTasbihOnly = false;
                                });
                              },
                              style: TextButton.styleFrom(foregroundColor: AppColors.activeGlow),
                              child: const Text('Reset'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sections
                      _filterSectionLabel('Frequency'),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: SunnahFrequency.values.map((f) => _buildFilterChip(
                          label: _frequencyLabel(f),
                          selected: tempFrequencies.contains(f),
                          onSelected: (s) => setModalState(() => s ? tempFrequencies.add(f) : tempFrequencies.remove(f)),
                        )).toList(),
                      ),

                      const SizedBox(height: 20),
                      _filterSectionLabel('Difficulty'),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: SunnahDifficulty.values.map((d) => _buildFilterChip(
                          label: _difficultyLabel(d),
                          selected: tempDifficulties.contains(d),
                          onSelected: (s) => setModalState(() => s ? tempDifficulties.add(d) : tempDifficulties.remove(d)),
                        )).toList(),
                      ),

                      const SizedBox(height: 20),
                      _filterSectionLabel('Categories'),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: viewCache.availableCategories.map((c) => _buildFilterChip(
                          label: c,
                          selected: tempCategories.contains(c),
                          onSelected: (s) => setModalState(() => s ? tempCategories.add(c) : tempCategories.remove(c)),
                        )).toList(),
                      ),

                      const SizedBox(height: 20),
                      _filterSectionLabel('Features'),
                      _buildFilterChip(
                        label: 'Tasbih-linked only',
                        selected: tempTasbihOnly,
                        onSelected: (s) => setModalState(() => tempTasbihOnly = s),
                      ),

                      const SizedBox(height: 30),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFrequencies..clear()..addAll(tempFrequencies);
                              _selectedDifficulties..clear()..addAll(tempDifficulties);
                              _selectedCategories..clear()..addAll(tempCategories);
                              _tasbihOnly = tempTasbihOnly;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.activeGlow.withValues(alpha: 0.25),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.activeGlow.withValues(alpha: 0.4)),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Apply Filters', style: AppTextStyles.body(color: Colors.white).copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI: Details Sheet ---

  void _openSunnahSheet(BuildContext context, Sunnah sunnah) {
    final isDhikrLinked = _tasbihLaunchForSunnah(sunnah) != null;
    final detailText = _detailDescription(sunnah);
    final currentState = context.read<SunnahBloc>().state;
    final practicedToday =
        currentState is SunnahLoaded &&
        currentState.progress.isPracticedToday(sunnah.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _buildGlassSheet(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.activeGlow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.activeGlow.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          sunnah.category.toUpperCase(),
                          style: AppTextStyles.tiny(color: AppColors.activeGlow).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(sunnah.title, style: AppTextStyles.h2(color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildMetaRow(sunnah),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    detailText,
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9)).copyWith(height: 1.5),
                  ),

                  // Arabic Section
                  if (sunnah.arabic != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            sunnah.arabic!,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.arabicLarge(color: Colors.white),
                          ),
                          if (sunnah.translation != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              sunnah.translation!,
                              style: AppTextStyles.small(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Reference
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _referenceText(sunnah),
                          style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _markSunnahPracticed(context, sunnah);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            practicedToday
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                            color: practicedToday
                                ? AppColors.activeGlow
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                          label: Text(
                            practicedToday
                                ? 'Practiced Today'
                                : 'Mark Practiced',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (isDhikrLinked) const SizedBox(width: 10),
                      if (isDhikrLinked)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openTasbih(context, sunnah: sunnah);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.activeGlow.withValues(alpha: 0.25),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.activeGlow.withValues(alpha: 0.4)),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.touch_app_rounded, size: 20),
                            label: const Text(
                              'Start Tasbih',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
      },
    );
  }

  // --- Helper Widgets & Methods ---

  Widget _buildGlassSheet({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _filterSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6)).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.activeGlow,
      selectedColor: AppColors.activeGlow.withValues(alpha: 0.15),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: AppTextStyles.small(
        color: selected ? AppColors.activeGlow : Colors.white.withValues(alpha: 0.7),
      ).copyWith(fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.activeGlow.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMetaRow(Sunnah sunnah) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metaPill(_difficultyLabel(sunnah.difficulty), _difficultyColor(sunnah.difficulty)),
        _metaPill(_frequencyLabel(sunnah.frequency), Colors.white.withValues(alpha: 0.7)),
      ],
    );
  }

  Widget _metaPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTextStyles.tiny(color: color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Existing Utility Methods (Unchanged) ---
  // Kept your utility methods (formatters, data getters, nav helpers) exactly as they were
  // to ensure business logic remains consistent.

  void _openTasbih(BuildContext context, {Sunnah? sunnah}) {
    final launch = sunnah != null ? _tasbihLaunchForSunnah(sunnah) : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbihScreen(
          initialTasbihId: launch?.initialTasbihId,
          initialQuery: launch?.initialQuery ?? sunnah?.title,
          sourceSunnah: sunnah,
        ),
      ),
    );
  }

  String _referenceText(Sunnah sunnah) {
    final parts = <String>[sunnah.reference['book'] ?? 'Hadith Reference'];
    if (sunnah.reference['hadith']?.isNotEmpty ?? false) parts.add(sunnah.reference['hadith']!);
    if (sunnah.reference['narrator']?.isNotEmpty ?? false) parts.add('Narrated by ${sunnah.reference['narrator']}');
    if (sunnah.reference['grade']?.isNotEmpty ?? false) parts.add('Grade: ${sunnah.reference['grade']}');
    return parts.join(' • ');
  }

  String _shortReference(String? hadith) {
    if (hadith == null || hadith.isEmpty) return 'Reference';
    final collapsed = hadith.replaceAll(', ', ' · ');
    return collapsed.length <= 26 ? collapsed : '${collapsed.substring(0, 23)}...';
  }

  String _tileSubtitle(Sunnah sunnah) {
    final detail = _detailDescription(sunnah);
    if (detail == sunnah.description) return detail;
    final hadith = sunnah.reference['hadith'];
    return (hadith != null && hadith.isNotEmpty) ? 'Hadith: $hadith' : detail;
  }

  String _detailDescription(Sunnah sunnah) {
    final titleNorm = _normalizeText(sunnah.title);
    final description = sunnah.description.trim();
    if (_normalizeText(description).startsWith(titleNorm)) {
      final hadith = sunnah.reference['hadith'];
      return (hadith != null && hadith.isNotEmpty) ? 'Mentioned in $hadith.' : description;
    }
    return description;
  }

  String _normalizeText(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  void _showAppSnackBar(BuildContext context, {required String message, IconData? icon}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GlassContainer(
          borderRadius: 16,
          blur: 10,
          opacity: 0.1,
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.activeGlow, size: 20), const SizedBox(width: 12)],
              Expanded(child: Text(message, style: AppTextStyles.small(color: Colors.white))),
            ],
          ),
        ),
      ));
  }

  String _weekLabel() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return 'Week of ${_formatDate(monday)}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Map<String, List<Sunnah>> _groupSunnahsByCategory(List<Sunnah> sunnahs) {
    final grouped = <String, List<Sunnah>>{};
    for (final sunnah in sunnahs) {
      grouped.putIfAbsent(sunnah.category, () => []).add(sunnah);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => _categorySortIndex(a).compareTo(_categorySortIndex(b)));
    return {for (var k in sortedKeys) k: grouped[k]!..sort((a, b) => a.title.compareTo(b.title))};
  }

  bool _isCategoryExpanded(String category) => _expandAll || _expandedCategories.contains(category);

  void _toggleCategory(String category) {
    setState(() {
      _expandAll = false;
      _expandedCategories.contains(category) ? _expandedCategories.remove(category) : _expandedCategories.add(category);
    });
  }

  void _toggleExpandAll(Map<String, List<Sunnah>> grouped) {
    setState(() {
      _expandAll = !_expandAll;
      _expandAll ? _expandedCategories.addAll(grouped.keys) : _expandedCategories.clear();
    });
  }

  String _sectionTypeSummary(List<Sunnah> sunnahs) {
    final ordered = [SunnahFrequency.daily, SunnahFrequency.weekly, SunnahFrequency.monthly, SunnahFrequency.occasional];
    final available = ordered.where((f) => sunnahs.any((s) => s.frequency == f)).map(_frequencyLabel).toList();
    return available.isEmpty ? '${sunnahs.length} sunnahs' : '${sunnahs.length} sunnahs · ${available.join(', ')}';
  }

  int _categorySortIndex(String category) {
    const order = {
      'Eating & Drinking': 0, 'Personal Hygiene': 1, 'Social Etiquette': 2, 'Social Etiquette & Character': 2,
      'Sleep & Waking': 3, 'Masjid & Prayer': 4, 'Fasting': 5, 'Family & Relationships': 6,
      'Charity & Generosity': 7, 'Knowledge & Dhikr': 8, 'Travel': 9, 'Miscellaneous': 10, 'Miscellaneous Daily Sunnahs': 10
    };
    return order[category] ?? 100;
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Eating & Drinking': return Icons.restaurant_rounded;
      case 'Personal Hygiene': return Icons.spa_outlined;
      case 'Social Etiquette': case 'Social Etiquette & Character': return Icons.handshake_outlined;
      case 'Sleep & Waking': return Icons.nightlight_round;
      case 'Masjid & Prayer': return Icons.mosque_outlined;
      case 'Fasting': return Icons.dark_mode_outlined;
      case 'Family & Relationships': return Icons.family_restroom_outlined;
      case 'Charity & Generosity': return Icons.volunteer_activism_outlined;
      case 'Knowledge & Dhikr': return Icons.menu_book_rounded;
      case 'Travel': return Icons.flight_takeoff_rounded;
      default: return Icons.auto_awesome_outlined;
    }
  }

  String _difficultyLabel(SunnahDifficulty d) {
    switch (d) { case SunnahDifficulty.easy: return 'Easy'; case SunnahDifficulty.medium: return 'Medium'; case SunnahDifficulty.advanced: return 'Advanced'; }
  }

  Color _difficultyColor(SunnahDifficulty d) {
    switch (d) { case SunnahDifficulty.easy: return const Color(0xFF73D38A); case SunnahDifficulty.medium: return const Color(0xFFFFC266); case SunnahDifficulty.advanced: return const Color(0xFFFF8C8C); }
  }

  String _frequencyLabel(SunnahFrequency f) {
    switch (f) { case SunnahFrequency.daily: return 'Daily'; case SunnahFrequency.weekly: return 'Weekly'; case SunnahFrequency.monthly: return 'Monthly'; case SunnahFrequency.occasional: return 'Occasional'; }
  }

  _TasbihLaunch? _tasbihLaunchForSunnah(Sunnah sunnah) {
    // Use cached value first, then fall back to model's tasbihId
    final cached = _viewCache?.tasbihLaunchById[sunnah.id];
    if (cached != null) return cached;
    if (sunnah.tasbihId != null) {
      return _TasbihLaunch(initialTasbihId: sunnah.tasbihId!, initialQuery: sunnah.title);
    }
    return null;
  }
}

class _TasbihLaunch {
  final String initialTasbihId;
  final String? initialQuery;
  const _TasbihLaunch({required this.initialTasbihId, this.initialQuery});
}

class _SunnahViewCache {
  final List<Sunnah> remaining;
  final Map<String, List<Sunnah>> grouped;
  final List<MapEntry<String, List<Sunnah>>> groupedEntries;
  final List<String> availableCategories;
  final Map<String, _TasbihLaunch?> tasbihLaunchById;

  const _SunnahViewCache({
    required this.remaining,
    required this.grouped,
    required this.groupedEntries,
    required this.availableCategories,
    required this.tasbihLaunchById,
  });
}
