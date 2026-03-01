import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/common/glass_snackbar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/sunnah.dart';
import '../../../widgets/common/glass_container.dart';
import '../../tasbih/screens/tasbih_screen.dart';
import '../bloc/sunnah_bloc.dart';
import '../widgets/sunnah_category_block.dart';
import '../widgets/sunnah_other_header.dart';
import '../widgets/sunnah_page_header.dart'; // Kept for imports, but using inline custom header
import '../widgets/sunnah_tile.dart';
import '../widgets/sunnah_weekly_card.dart';
import '../../../widgets/common/premium_flowing_loader.dart';

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
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SunnahBloc, SunnahState>(
          builder: (context, state) {
            if (state is SunnahLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PremiumFlowingLoader(size: 50.0, color: AppColors.spiritualGold),
                    const SizedBox(height: 24),
                    Text(
                      'Loading Sunnahs...',
                      style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w500).copyWith(letterSpacing: 1.2),
                    ),
                  ],
                ),
              );
            }

            if (state is SunnahError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, color: Colors.white.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load Sunnahs',
                        style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.read<SunnahBloc>().add(LoadSunnahs()),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            ),
                        ),
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

    final size = MediaQuery.sizeOf(context);
    final bool isSmallPhone = size.width < 360;
    final double hPad = (size.width * 0.05).clamp(16.0, 24.0);

    final showWeeklySunnah = weeklySunnah != null &&
        filteredSunnahs.any((sunnah) => sunnah.id == weeklySunnah.id);

    late final List<Sunnah> remaining;
    late final Map<String, List<Sunnah>> grouped;
    late final List<MapEntry<String, List<Sunnah>>> groupedEntries;

    if (!_hasActiveFilters && showWeeklySunnah) {
      remaining = viewCache.remaining;
      grouped = viewCache.grouped;
      groupedEntries = viewCache.groupedEntries;
    } else {
      remaining = filteredSunnahs
          .where((sunnah) => sunnah.id != weeklySunnah?.id)
          .toList(growable: false);
      grouped = _groupSunnahsByCategory(remaining);
      groupedEntries = grouped.entries.toList(growable: false);
    }

    _expandedCategories.removeWhere((category) => !grouped.containsKey(category));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Header Section (Sleek Inline Design)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, (size.height * 0.03).clamp(16.0, 24.0), hPad, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE PROPHETIC PATH',
                  style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                      .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Sunnah', style: AppTextStyles.h1()),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
          ),
        ),

        // 2. Weekly Sunnah Card
        if (showWeeklySunnah)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
              child: SunnahWeeklyCard(
                sunnah: weeklySunnah,
                weekLabel: _weekLabel(),
                isDhikrLinked: _tasbihLaunchForSunnah(weeklySunnah) != null,
                categoryIcon: _iconForCategory(weeklySunnah.category),
                difficultyLabel: _difficultyLabel(weeklySunnah.difficulty),
                frequencyLabel: _frequencyLabel(weeklySunnah.frequency),
                isPracticedToday: progress.isPracticedToday(weeklySunnah.id),
                onPracticeTap: () => _markSunnahPracticed(context, weeklySunnah),
                onReadDetailsTap: () => _openSunnahSheet(context, weeklySunnah),
                onOpenTasbihTap: () => _openTasbih(context, sunnah: weeklySunnah),
                onSkipTap: () => context.read<SunnahBloc>().add(SkipWeeklySunnah()),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
            ),
          ),

        // 3. List Header & Filters
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
            child: SunnahOtherHeader(
              count: remaining.length,
              expandAll: _expandAll,
              activeFilterCount: _activeFilterCount,
              activeFilterTags: _activeFilterTags(),
              onToggleExpandAll: () => _toggleExpandAll(grouped),
              onOpenFilters: () => _openFilterSheet(context, viewCache, isSmallPhone),
              onRemoveTag: _handleRemoveTag,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ),
        ),

        // 4. Content or Empty State
        if (remaining.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.filter_list_off_rounded, color: Colors.white.withValues(alpha: 0.3), size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'No Sunnahs match your filters.',
                      style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.8)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Clear Filters'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.spiritualGold),
                    )
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
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
                ).animate().fadeIn(delay: Duration(milliseconds: 250 + (index * 50)), duration: 400.ms);
              }, childCount: groupedEntries.length),
            ),
          ),

        SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 80)),
      ],
    );
  }

  // --- Logic for Filters & Tags ---

  void _handleRemoveTag(String tag) {
    setState(() {
      for (final freq in SunnahFrequency.values) {
        if (_frequencyLabel(freq) == tag) {
          _selectedFrequencies.remove(freq);
          return;
        }
      }
      for (final diff in SunnahDifficulty.values) {
        if (_difficultyLabel(diff) == tag) {
          _selectedDifficulties.remove(diff);
          return;
        }
      }
      if (tag == 'Tasbih-linked') {
        _tasbihOnly = false;
        return;
      }
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
        sunnah.id: _tasbihLaunchForSunnahDirect(sunnah),
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

  void _markSunnahPracticed(BuildContext context, Sunnah sunnah) {
    HapticFeedback.mediumImpact();
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

  Future<void> _openFilterSheet(BuildContext context, _SunnahViewCache viewCache, bool isSmallPhone) async {
    HapticFeedback.lightImpact();
    final tempFrequencies = Set<SunnahFrequency>.from(_selectedFrequencies);
    final tempDifficulties = Set<SunnahDifficulty>.from(_selectedDifficulties);
    final tempCategories = Set<String>.from(_selectedCategories);
    var tempTasbihOnly = _tasbihOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: EdgeInsets.fromLTRB(isSmallPhone ? 20 : 24, 12, isSmallPhone ? 20 : 24, 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40, height: 4,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Filter Sunnahs', style: AppTextStyles.h2(color: Colors.white)),
                              if (tempFrequencies.isNotEmpty || tempDifficulties.isNotEmpty || tempCategories.isNotEmpty || tempTasbihOnly)
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() {
                                      tempFrequencies.clear();
                                      tempDifficulties.clear();
                                      tempCategories.clear();
                                      tempTasbihOnly = false;
                                    });
                                  },
                                  style: TextButton.styleFrom(foregroundColor: AppColors.spiritualGold),
                                  child: const Text('Reset'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _filterSectionLabel('Frequency'),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: SunnahFrequency.values.map((f) => _buildFilterChip(
                              label: _frequencyLabel(f),
                              selected: tempFrequencies.contains(f),
                              onSelected: (s) {
                                HapticFeedback.selectionClick();
                                setModalState(() => s ? tempFrequencies.add(f) : tempFrequencies.remove(f));
                              },
                            )).toList(),
                          ),

                          const SizedBox(height: 24),
                          _filterSectionLabel('Difficulty'),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: SunnahDifficulty.values.map((d) => _buildFilterChip(
                              label: _difficultyLabel(d),
                              selected: tempDifficulties.contains(d),
                              onSelected: (s) {
                                HapticFeedback.selectionClick();
                                setModalState(() => s ? tempDifficulties.add(d) : tempDifficulties.remove(d));
                              },
                            )).toList(),
                          ),

                          const SizedBox(height: 24),
                          _filterSectionLabel('Categories'),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: viewCache.availableCategories.map((c) => _buildFilterChip(
                              label: c,
                              selected: tempCategories.contains(c),
                              onSelected: (s) {
                                HapticFeedback.selectionClick();
                                setModalState(() => s ? tempCategories.add(c) : tempCategories.remove(c));
                              },
                            )).toList(),
                          ),

                          const SizedBox(height: 24),
                          _filterSectionLabel('Features'),
                          _buildFilterChip(
                            label: 'Tasbih-linked only',
                            selected: tempTasbihOnly,
                            onSelected: (s) {
                              HapticFeedback.selectionClick();
                              setModalState(() => tempTasbihOnly = s);
                            },
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedFrequencies..clear()..addAll(tempFrequencies);
                                  _selectedDifficulties..clear()..addAll(tempDifficulties);
                                  _selectedCategories..clear()..addAll(tempCategories);
                                  _tasbihOnly = tempTasbihOnly;
                                });
                                Navigator.of(sheetContext).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.spiritualGold.withValues(alpha: 0.2),
                                foregroundColor: AppColors.spiritualGold,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.spiritualGold.withValues(alpha: 0.4), width: 0.5),
                                ),
                                elevation: 0,
                              ),
                              child: Text('Apply Filters', style: AppTextStyles.body(color: AppColors.spiritualGold).copyWith(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    HapticFeedback.lightImpact();
    final isDhikrLinked = _tasbihLaunchForSunnah(sunnah) != null;
    final detailText = _detailDescription(sunnah);
    final currentState = context.read<SunnahBloc>().state;
    final practicedToday =
        currentState is SunnahLoaded &&
            currentState.progress.isPracticedToday(sunnah.id);

    final size = MediaQuery.sizeOf(context);
    final isSmallPhone = size.width < 360;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: EdgeInsets.fromLTRB(isSmallPhone ? 20 : 24, 12, isSmallPhone ? 20 : 24, 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.spiritualGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Text(
                              sunnah.category.toUpperCase(),
                              style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(sunnah.title, style: AppTextStyles.h2(color: Colors.white).copyWith(fontSize: isSmallPhone ? 20 : 24)),
                      const SizedBox(height: 16),

                      _buildMetaRow(sunnah),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        detailText,
                        style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9)).copyWith(height: 1.6),
                      ),

                      // Elegant Arabic Section
                      if (sunnah.arabic != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                sunnah.arabic!,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: isSmallPhone ? 24 : 28,
                                  color: AppColors.spiritualGold.withValues(alpha: 0.9),
                                  height: 1.8,
                                ),
                              ),
                              if (sunnah.translation != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 40),
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.2), Colors.transparent]),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '“${sunnah.translation!}”',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)).copyWith(fontStyle: FontStyle.italic),
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
                          Icon(Icons.menu_book_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _referenceText(sunnah),
                              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _markSunnahPracticed(context, sunnah);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: practicedToday
                                    ? AppColors.statusOnTime.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                foregroundColor: practicedToday ? AppColors.statusOnTime : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: practicedToday
                                        ? AppColors.statusOnTime.withValues(alpha: 0.4)
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              icon: Icon(
                                practicedToday ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                practicedToday ? 'Done Today' : 'Mark Practiced',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (isDhikrLinked) const SizedBox(width: 12),
                          if (isDhikrLinked)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _openTasbih(context, sunnah: sunnah);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.spiritualGold.withValues(alpha: 0.2),
                                  foregroundColor: AppColors.spiritualGold,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppColors.spiritualGold.withValues(alpha: 0.4), width: 0.5),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.touch_app_rounded, size: 18),
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
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets & Methods ---

  Widget _filterSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
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
      showCheckmark: false, // Removed checkmark for cleaner look
      selectedColor: AppColors.spiritualGold.withValues(alpha: 0.2),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: AppTextStyles.small(
        color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7),
      ).copyWith(fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.spiritualGold.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildMetaRow(Sunnah sunnah) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metaPill(_difficultyLabel(sunnah.difficulty), _difficultyColor(sunnah.difficulty)),
        _metaPill(_frequencyLabel(sunnah.frequency), Colors.white.withValues(alpha: 0.8)),
      ],
    );
  }

  Widget _metaPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.tiny(color: color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Existing Utility Methods (Unchanged) ---

  void _openTasbih(BuildContext context, {Sunnah? sunnah}) {
    final launch = sunnah != null ? _tasbihLaunchForSunnah(sunnah) : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbihScreen(
          initialTasbihId: launch?.initialTasbihId,
          initialQuery: launch?.initialQuery ?? sunnah?.title,
          initialFlow: launch?.initialFlow,
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
    GlassSnackBar.show(
      context,
      message: message,
      icon: icon,
    );
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
      'Dhikr & Azkar': -1, 'Eating & Drinking': 0, 'Personal Hygiene': 1, 'Social Etiquette': 2, 'Social Etiquette & Character': 2,
      'Sleep & Waking': 3, 'Masjid & Prayer': 4, 'Fasting': 5, 'Family & Relationships': 6,
      'Charity & Generosity': 7, 'Knowledge': 8, 'Knowledge & Dhikr': 8, 'Travel': 9, 'Miscellaneous': 10, 'Miscellaneous Daily Sunnahs': 10
    };
    return order[category] ?? 100;
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Dhikr & Azkar': return Icons.fingerprint_rounded;
      case 'Eating & Drinking': return Icons.restaurant_rounded;
      case 'Personal Hygiene': return Icons.spa_outlined;
      case 'Social Etiquette': case 'Social Etiquette & Character': return Icons.handshake_outlined;
      case 'Sleep & Waking': return Icons.nightlight_round;
      case 'Masjid & Prayer': return Icons.mosque_outlined;
      case 'Fasting': return Icons.dark_mode_outlined;
      case 'Family & Relationships': return Icons.family_restroom_outlined;
      case 'Charity & Generosity': return Icons.volunteer_activism_outlined;
      case 'Knowledge': case 'Knowledge & Dhikr': return Icons.menu_book_rounded;
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
    final cached = _viewCache?.tasbihLaunchById[sunnah.id];
    if (cached != null) return cached;
    return _tasbihLaunchForSunnahDirect(sunnah);
  }

  static _TasbihLaunch? _tasbihLaunchForSunnahDirect(Sunnah sunnah) {
    if (sunnah.tasbihId == null) return null;

    String? flowId;
    final titleLower = sunnah.title.toLowerCase();
    if (titleLower.contains('fatimah')) {
      flowId = 'fatimah';
    } else if (titleLower.contains('before sleep') || titleLower.contains('before-sleep')) {
      flowId = 'before_sleep';
    } else if (titleLower.contains('after prayer') || titleLower.contains('after salah')) {
      flowId = 'after_prayer';
    }
    return _TasbihLaunch(
      initialTasbihId: sunnah.tasbihId!,
      initialQuery: sunnah.title,
      initialFlow: flowId,
    );
  }
}

class _TasbihLaunch {
  final String initialTasbihId;
  final String? initialQuery;
  final String? initialFlow;
  const _TasbihLaunch({required this.initialTasbihId, this.initialQuery, this.initialFlow});
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