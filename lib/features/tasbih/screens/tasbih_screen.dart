import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/common/glass_snackbar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../features/home/bloc/prayer_bloc.dart';
import '../../../features/home/widgets/celestial_background.dart';
import '../../../models/settings.dart';
import '../../../models/sunnah.dart';
import '../../../models/tasbih.dart';
import '../../../models/tasbih_flow.dart';
import '../../../models/azkar.dart';
import '../../../core/repositories/azkar_repository.dart';
import '../../../core/utils/azkar_to_tasbih_mapper.dart';
import '../bloc/tasbih_bloc.dart';
import '../../../widgets/common/premium_flowing_loader.dart';


class TasbihScreen extends StatefulWidget {
  final String? initialTasbihId;
  final String? initialQuery;
  final String? initialFlow;
  final Sunnah? sourceSunnah;
  final AzkarCategory? initialAzkarCategory;

  const TasbihScreen({
    super.key,
    this.initialTasbihId,
    this.initialQuery,
    this.initialFlow,
    this.sourceSunnah,
    this.initialAzkarCategory,
  });

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final TasbihRepository _tasbihRepository = TasbihRepository();
  final StorageService _storageService = StorageService();
  final AzkarRepository _azkarRepository = AzkarRepository();

  Tasbih? _selectedTasbih;
  bool _didResolveInitialSelection = false;
  bool _flowPrepared = false;
  bool _isLoadingAzkar = false;

  // Flow state
  TasbihFlow? _activeFlow;
  int _activePhaseIndex = 0;
  bool _phaseCompleting = false;
  bool _flowCompleted = false;

  Sunnah? _activeSunnah;
  Map<String, Sunnah>? _sunnahByTasbihId;

  @override
  void initState() {
    super.initState();
    // Support direct launch (like from Sunnah Screen) using initialTasbihId mappings
    final mappedCategory = widget.initialTasbihId != null 
        ? _mapTasbihIdToCategory(widget.initialTasbihId!) 
        : null;

    final resolvedAzkarCategory = widget.initialAzkarCategory ?? mappedCategory;

    if (resolvedAzkarCategory != null) {
      _isLoadingAzkar = true;
      _activateDynamicAzkarCategory(resolvedAzkarCategory);
    }
  }

  Future<void> _activateDynamicAzkarCategory(AzkarCategory category) async {
    try {
      final azkars = await _azkarRepository.getAzkarByCategory(category);
      final flowName = category.name.toUpperCase();
      final flow = AzkarToTasbihMapper.toTasbihFlow(
        flowId: 'dynamic_azkar_${category.name}',
        flowName: '$flowName AZKAR',
        azkarList: azkars,
      );
      if (mounted) {
        setState(() {
          _activeFlow = flow;
          _activePhaseIndex = 0;
          _isLoadingAzkar = false;
        });

        if (flow.phases.isNotEmpty) {
           final currentState = context.read<TasbihBloc>().state;
           final tasbihs = currentState is TasbihLoaded ? currentState.tasbihs : <Tasbih>[];
           
           for (final phase in flow.phases) {
              final item = _findTasbihById(tasbihs, phase.tasbihId, fallbackTarget: phase.target);
              if (item != null && item.currentCount != 0) {
                 final reset = item.copyWith(currentCount: 0, lastUpdated: DateTime.now());
                 context.read<TasbihBloc>().add(UpdateTasbih(reset));
              }
           }
           final firstItem = _findTasbihById(tasbihs, flow.phases.first.tasbihId, fallbackTarget: flow.phases.first.target);
           if (mounted && firstItem != null) {
              setState(() {
                 _selectedTasbih = firstItem;
                 _didResolveInitialSelection = true;
              });
           }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAzkar = false);
    }
  }

  AzkarCategory? _mapTasbihIdToCategory(String id) {
    if (id == 'morning_azkar') return AzkarCategory.morning;
    if (id == 'evening_azkar') return AzkarCategory.evening;
    if (id == 'before_sleep_azkar') return AzkarCategory.beforeSleep;
    if (id == 'after_prayer') return AzkarCategory.afterPrayer;
    return null;
  }

  // Replaced multiple load functions with unified `_activateDynamicAzkarCategory`


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerBloc, PrayerState>(
      builder: (context, prayerState) {
        final settings = _storageService.getSettings();

        return CelestialBackground(
          prayerPeriod: _prayerPeriodFromState(prayerState),
          weatherCondition: _weatherConditionFromTheme(settings.weatherTheme),
          cloudCoverage: _cloudCoverageFromTheme(settings.weatherTheme),
          latitude: settings.location?.latitude ?? 0.0,
          showCelestialBody: false,
          child: BlocConsumer<TasbihBloc, TasbihState>(
            listener: (context, state) {
              if (state is TasbihLoaded && !_didResolveInitialSelection) {
                _prepareFlowIfNeeded(state.tasbihs);
                _selectedTasbih =
                    _resolveInitialTasbih(state.tasbihs) ??
                        (state.tasbihs.isNotEmpty ? state.tasbihs.first : null);
                _didResolveInitialSelection = true;
              }
            },
            builder: (context, state) {
              if (state is TasbihLoading || _isLoadingAzkar) {
                return const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(child: PremiumFlowingLoader(color: AppColors.activeGlow)),
                );
              }

              if (state is TasbihError) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: AppTextStyles.body(color: Colors.white),
                    ),
                  ),
                );
              }

              if (state is TasbihLoaded) {
                _prepareFlowIfNeeded(state.tasbihs);
                _selectedTasbih ??=
                    _resolveInitialTasbih(state.tasbihs) ??
                        (state.tasbihs.isNotEmpty ? state.tasbihs.first : null);
                _didResolveInitialSelection = true;

                if (_selectedTasbih != null) {
                  try {
                    final found = _findTasbihById(
                      state.tasbihs, 
                      _selectedTasbih!.id, 
                      fallbackTarget: _selectedTasbih!.targetCount
                    );
                    _selectedTasbih = found ?? _selectedTasbih;
                    
                    if (_activeFlow != null) {
                      final flowIdx = _activeFlow!.phases
                          .indexWhere((p) => p.tasbihId == _selectedTasbih!.id);
                      if (flowIdx >= 0) {
                        _activePhaseIndex = flowIdx;
                      }
                    }
                  } catch (_) {
                    _selectedTasbih =
                    state.tasbihs.isNotEmpty ? state.tasbihs.first : null;
                  }
                }

                if (_selectedTasbih == null) {
                  return const Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: Text('No Tasbihs found', style: TextStyle(color: Colors.white)),
                    ),
                  );
                }

                _activeSunnah = _resolveSunnahForTasbih(_selectedTasbih!);

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _buildHeader(state.tasbihs).animate().fadeIn(duration: 400.ms),

                            Expanded(
                              // 1. FULL SCREEN TAP ZONE: Tap anywhere to count
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _phaseCompleting || _flowCompleted
                                    ? null
                                    : () => _onCounterTap(state.tasbihs),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                        child: IntrinsicHeight(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Spacer(flex: 1),

                                              // Selector Pill
                                              _buildSelectorPill(state.tasbihs)
                                                  .animate()
                                                  .fadeIn(delay: 100.ms, duration: 400.ms)
                                                  .slideY(begin: 0.1, curve: Curves.easeOut),

                                              const SizedBox(height: 24),

                                              // Content Card (Arabic / Translation)
                                              _buildContentCard()
                                                  .animate()
                                                  .fadeIn(delay: 200.ms, duration: 400.ms)
                                                  .slideY(begin: 0.1, curve: Curves.easeOut),

                                              const SizedBox(height: 48),

                                              // Interactive Counter
                                              _buildCounter()
                                                  .animate()
                                                  .fadeIn(delay: 300.ms, duration: 500.ms)
                                                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                                              const SizedBox(height: 48),

                                              // Footer Stats
                                              _buildFooterStats()
                                                  .animate()
                                                  .fadeIn(delay: 400.ms, duration: 400.ms),

                                              const Spacer(flex: 2),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Completion overlay
                        if (_flowCompleted) _buildCompletionOverlay(),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildHeader(List<Tasbih> tasbihs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (Navigator.canPop(context))
            _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOCUS',
                  style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5))
                      .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                ),
                Text('Digital Tasbih', style: AppTextStyles.h2()),
              ],
            ),

          Row(
            children: [
              _GlassIconButton(
                icon: Icons.refresh_rounded,
                onTap: () => _showResetDialog(context),
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.list_rounded,
                onTap: () => _showTasbihList(context, tasbihs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorPill(List<Tasbih> tasbihs) {
    return GestureDetector(
      // Stop the tap from bleeding down to the full-screen counter
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTasbihList(context, tasbihs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.activeGlow, size: 18),
                const SizedBox(width: 12),
                Text(
                  _selectedTasbih!.name,
                  style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    // In a flow, show the current phase's content
    final phase = _activeFlow != null && _activePhaseIndex < _activeFlow!.phases.length
        ? _activeFlow!.phases[_activePhaseIndex]
        : null;

    final arabic = phase?.arabic ?? _activeSunnah?.arabic;
    final transliteration = phase?.transliteration ?? _activeSunnah?.transliteration;
    final translation = phase?.translation ?? _activeSunnah?.translation;
    final virtue = phase?.virtue;
    final hint = _recitationHint(_selectedTasbih!);

    if (arabic == null && transliteration == null && translation == null && hint == null && virtue == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                if (arabic != null) ...[
                  Text(
                    arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (transliteration != null) ...[
                  Text(
                    transliteration,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(color: AppColors.kaabaGold.withValues(alpha: 0.9))
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                ],
                if (translation != null) ...[
                  Text(
                    '"$translation"',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
                if (virtue != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusOnTime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusOnTime.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.statusOnTime.withValues(alpha: 0.8), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            virtue,
                            style: AppTextStyles.tiny(color: AppColors.statusOnTime.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (arabic == null && hint != null) ...[
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    final percent = (_selectedTasbih!.currentCount / _selectedTasbih!.targetCount).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.activeGlow.withValues(alpha: 0.15),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: CircularPercentIndicator(
        radius: 130.0,
        lineWidth: 12.0,
        percent: percent,
        // 2. Center background circle removed for a cleaner look
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_selectedTasbih!.currentCount}',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              '/ ${_selectedTasbih!.targetCount}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        progressColor: AppColors.activeGlow,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        circularStrokeCap: CircularStrokeCap.round,
        animation: true,
        animateFromLastPercent: true,
        animationDuration: 150,
      ),
    );
  }

  Widget _buildFooterStats() {
    return Column(
      children: [
        if (_isSequencedFlow) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.spiritualGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_rounded, size: 14, color: AppColors.spiritualGold),
                const SizedBox(width: 8),
                Text(
                  '${_activeFlow!.name}  ${_activePhaseIndex + 1}/${_activeFlow!.phases.length}',
                  style: AppTextStyles.small(color: AppColors.spiritualGold).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.all_inclusive_rounded, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              'LIFETIME COUNT: ${_selectedTasbih!.totalCount}',
              style: AppTextStyles.tiny(color: Colors.white54).copyWith(letterSpacing: 2),
            ),
          ],
        ),
      ],
    );
  }

  /// Gold shimmer overlay shown when a multi-phase flow is fully completed.
  Widget _buildCompletionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.spiritualGold.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.spiritualGold.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 56, color: AppColors.spiritualGold),
                ),
                const SizedBox(height: 28),
                Text(
                  _activeFlow?.name ?? 'Flow Complete',
                  style: AppTextStyles.h2(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed',
                  style: AppTextStyles.body(color: AppColors.spiritualGold),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms),
      ),
    );
  }

  // ===========================================================================
  // LOGIC & ACTIONS
  // ===========================================================================

  void _onCounterTap(List<Tasbih> tasbihs) {
    if (_selectedTasbih == null || _phaseCompleting || _flowCompleted) return;

    final selected = _selectedTasbih!;
    final newCount = selected.currentCount + 1;

    // Haptic feedback engine
    if (newCount == selected.targetCount) {
      HapticFeedback.heavyImpact(); // Target reached
    } else if (newCount % 33 == 0 || newCount % 100 == 0) {
      HapticFeedback.mediumImpact(); // Milestone reached
    } else {
      HapticFeedback.lightImpact(); // Standard tap
    }

    int displayCount;
    if (_isSequencedFlow) {
      displayCount = newCount > selected.targetCount ? selected.targetCount : newCount;
    } else {
      displayCount = newCount;
      if (displayCount > selected.targetCount) {
        displayCount = 1; // Auto-reset for standard dhikr loops
      }
    }

    final updated = selected.copyWith(
      currentCount: displayCount,
      totalCount: selected.totalCount + 1,
      lastUpdated: DateTime.now(),
    );

    context.read<TasbihBloc>().add(UpdateTasbih(updated));

    if (_isSequencedFlow && displayCount >= selected.targetCount) {
      _advanceFlow(tasbihs);
    }
  }

  void _advanceFlow(List<Tasbih> tasbihs) {
    if (!_isSequencedFlow) return;

    // All phases completed
    if (_activePhaseIndex >= _activeFlow!.phases.length - 1) {
      setState(() => _flowCompleted = true);
      // Show completion overlay for 2 seconds, then dismiss
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _flowCompleted = false;
          _activeFlow = null;
          _activePhaseIndex = 0;
        });
      });
      return;
    }

    // Pause 500ms with phase-completing flag, then advance
    setState(() => _phaseCompleting = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final nextIndex = _activePhaseIndex + 1;
      final nextPhase = _activeFlow!.phases[nextIndex];
      // Lookup the item. It will generate an ephemeral Tasbih if one doesn't exist natively.
      final nextTasbih = _findTasbihById(tasbihs, nextPhase.tasbihId, fallbackTarget: nextPhase.target);
      if (nextTasbih == null) {
        setState(() => _phaseCompleting = false);
        return;
      }

      var preparedNext = nextTasbih;
      if (preparedNext.currentCount != 0) {
        preparedNext = preparedNext.copyWith(currentCount: 0, lastUpdated: DateTime.now());
        context.read<TasbihBloc>().add(UpdateTasbih(preparedNext));
      }

      setState(() {
        _activePhaseIndex = nextIndex;
        _selectedTasbih = preparedNext;
        _phaseCompleting = false;
      });
    });
  }

  // ===========================================================================
  // BOTTOM SHEETS & DIALOGS
  // ===========================================================================

  void _showTasbihList(BuildContext context, List<Tasbih> tasbihs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetCtx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text('Select Dhikr', style: AppTextStyles.h2(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24, top: 8),
                        itemCount: tasbihs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          indent: 24,
                          endIndent: 24,
                        ),
                        itemBuilder: (_, index) {
                          final t = tasbihs[index];
                          final sunnah = _resolveSunnahForTasbih(t);
                          final subtitle = sunnah?.transliteration ?? 'Target: ${t.targetCount}';
                          final isSelected = t.id == _selectedTasbih?.id;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                final mappedCategory = _mapTasbihIdToCategory(t.id);
                                
                                if (mappedCategory != null) {
                                  setState(() {
                                    _isLoadingAzkar = true;
                                    _activeSunnah = sunnah;
                                  });
                                  _activateDynamicAzkarCategory(mappedCategory);
                                } else {
                                  setState(() {
                                    // Clear any existing azkar flow if selecting a normal tasbih
                                    if (_activeFlow?.id.startsWith('dynamic_azkar_') == true) {
                                      _activeFlow = null;
                                    }
                                    _selectedTasbih = t;
                                    _activeSunnah = sunnah;
                                  });
                                }
                                Navigator.pop(sheetCtx);
                              },
                              child: Container(
                                color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.name,
                                            style: isSelected
                                                ? AppTextStyles.body(color: AppColors.activeGlow).copyWith(fontWeight: FontWeight.bold)
                                                : AppTextStyles.body(color: Colors.white),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: AppColors.activeGlow, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('Reset Counter?', style: AppTextStyles.h2(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'This will reset the current count to 0. Lifetime progress is kept safe.',
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dlgCtx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Cancel', style: AppTextStyles.body(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedTasbih != null) {
                              final reset = _selectedTasbih!.copyWith(
                                currentCount: 0,
                                lastUpdated: DateTime.now(),
                              );
                              context.read<TasbihBloc>().add(UpdateTasbih(reset));
                            }
                            Navigator.pop(dlgCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusLate.withValues(alpha: 0.2),
                            foregroundColor: AppColors.statusLate,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.statusLate.withValues(alpha: 0.4)),
                            ),
                          ),
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }

  void _showAppSnackBar({required String message, IconData? icon}) {
    GlassSnackBar.show(
      context,
      message: message,
      icon: icon,
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  PrayerPeriod _prayerPeriodFromState(PrayerState state) {
    if (state is PrayerLoaded) return state.prayerPeriod;
    return PrayerPeriod.isha;
  }

  WeatherCondition _weatherConditionFromTheme(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.clear: return WeatherCondition.clear;
      case WeatherTheme.cloudy: return WeatherCondition.cloudy;
      case WeatherTheme.rain: return WeatherCondition.rain;
      case WeatherTheme.thunderstorm: return WeatherCondition.thunderstorm;
      case WeatherTheme.snow: return WeatherCondition.snow;
      case WeatherTheme.fog: return WeatherCondition.fog;
      case WeatherTheme.auto: return WeatherCondition.clear;
    }
  }

  int _cloudCoverageFromTheme(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.clear: return 0;
      case WeatherTheme.cloudy: return 90;
      case WeatherTheme.rain: return 100;
      case WeatherTheme.thunderstorm: return 100;
      case WeatherTheme.snow: return 100;
      case WeatherTheme.fog: return 40;
      case WeatherTheme.auto: return 0;
    }
  }

  bool get _isSequencedFlow => _activeFlow != null;

  void _prepareFlowIfNeeded(List<Tasbih> tasbihs) {
    if (_flowPrepared) return;
    _flowPrepared = true;

    if (widget.initialFlow != null && widget.initialAzkarCategory == null) {
      final flow = _tasbihRepository.getFlow(widget.initialFlow!);
      if (flow != null) {
        _activeFlow = flow;
        _activePhaseIndex = 0;
      }
    }

    if (_activeFlow != null) {
      for (final phase in _activeFlow!.phases) {
        final item = _findTasbihById(tasbihs, phase.tasbihId, fallbackTarget: phase.target);
        if (item != null && item.currentCount != 0) {
          final reset = item.copyWith(currentCount: 0, lastUpdated: DateTime.now());
          context.read<TasbihBloc>().add(UpdateTasbih(reset));
        }
      }
    }
  }

  Tasbih? _resolveInitialTasbih(List<Tasbih> tasbihs) {
    if (tasbihs.isEmpty) return null;
    if (_isSequencedFlow) {
      final first = _findTasbihById(tasbihs, _activeFlow!.phases.first.tasbihId);
      if (first != null) return first;
    }
    final initialId = widget.initialTasbihId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      for (final tasbih in tasbihs) {
        if (tasbih.id.toLowerCase() == initialId.toLowerCase()) return tasbih;
      }
    }
    final query = widget.initialQuery?.toLowerCase().trim();
    if (query == null || query.isEmpty) return null;

    final mappedId = _mapQueryToTasbihId(query);
    if (mappedId != null) {
      for (final tasbih in tasbihs) {
        if (tasbih.id.toLowerCase() == mappedId) return tasbih;
      }
    }
    for (final tasbih in tasbihs) {
      if ('${tasbih.id} ${tasbih.name}'.toLowerCase().contains(query)) {
        return tasbih;
      }
    }
    return null;
  }

  Tasbih? _findTasbihById(List<Tasbih> tasbihs, String id, {int fallbackTarget = 1}) {
    try {
      return tasbihs.firstWhere((t) => t.id == id);
    } catch (_) {
      return Tasbih(
        id: id,
        name: 'Dhikr',
        targetCount: fallbackTarget,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Sunnah? _resolveSunnahForTasbih(Tasbih tasbih) {
    if (widget.sourceSunnah?.tasbihId == tasbih.id) return widget.sourceSunnah;
    _sunnahByTasbihId ??= _buildSunnahLookup();
    return _sunnahByTasbihId![tasbih.id];
  }

  Map<String, Sunnah> _buildSunnahLookup() {
    try {
      final repo = context.read<SunnahRepository>();
      final sunnahs = repo.getAllSunnahsSync();
      final map = <String, Sunnah>{};
      for (final s in sunnahs) {
        if (s.tasbihId != null && !map.containsKey(s.tasbihId)) {
          map[s.tasbihId!] = s;
        }
      }
      return map;
    } catch (_) {
      return <String, Sunnah>{};
    }
  }

  String? _mapQueryToTasbihId(String query) {
    if (query.contains('fatimah')) return 'subhanallah';
    if (query.contains('morning')) return 'morning_azkar';
    if (query.contains('evening')) return 'evening_azkar';
    if (query.contains('before sleep') || query.contains('sleep') || query.contains('night')) return 'before_sleep_azkar';
    if (query.contains('subhan')) return 'subhanallah';
    if (query.contains('alhamdulillah')) return 'alhamdulillah';
    if (query.contains('allahu akbar') || query.contains('takbir')) return 'allahuakbar';
    if (query.contains('astaghfir')) return 'astaghfirullah';
    if (query.contains('la ilaha')) return 'la_ilaha_illallah';
    if (query.contains('salawat') || query.contains('durood')) return 'salawat';
    return null;
  }

  String? _recitationHint(Tasbih tasbih) {
    final sunnah = _resolveSunnahForTasbih(tasbih);
    if (sunnah != null) {
      if (sunnah.arabic != null) return null;
      return sunnah.description;
    }
    switch (tasbih.id) {
      case 'morning_azkar': return 'Recite: Ayat al-Kursi (1x), Ikhlas/Falaq/Nas (3x), and Sayyid al-Istighfar (1x).';
      case 'evening_azkar': return 'Recite: Ayat al-Kursi (1x), Ikhlas/Falaq/Nas (3x), and evening protection adhkar.';
      case 'before_sleep_azkar': return 'Before sleep: SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (34x).';
      case 'subhanallah': return 'Say: SubhanAllah.';
      case 'alhamdulillah': return 'Say: Alhamdulillah.';
      case 'allahuakbar': return 'Say: Allahu Akbar.';
      case 'astaghfirullah': return 'Say: Astaghfirullah.';
      case 'la_ilaha_illallah': return 'Say: La ilaha illallah.';
      case 'salawat': return 'Send salawat upon the Prophet ﷺ.';
      default: return null;
    }
  }
}

// ===========================================================================
// SHARED WIDGETS
// ===========================================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Ensure the button catches taps and doesn't trigger the background counter
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}