import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../features/home/bloc/prayer_bloc.dart';
import '../../../features/home/widgets/celestial_background.dart';
import '../../../models/settings.dart';
import '../../../models/sunnah.dart';
import '../../../models/tasbih.dart';
import '../bloc/tasbih_bloc.dart';

class TasbihScreen extends StatefulWidget {
  final String? initialTasbihId;
  final String? initialQuery;
  final String? initialFlow;
  final Sunnah? sourceSunnah; // enriched sunnah context for Arabic/transliteration

  const TasbihScreen({
    super.key,
    this.initialTasbihId,
    this.initialQuery,
    this.initialFlow,
    this.sourceSunnah,
  });

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  static const String _flowFatimah = 'fatimah';
  static const List<String> _fatimahSequence = <String>[
    'subhanallah',
    'alhamdulillah',
    'allahuakbar',
  ];

  final StorageService _storageService = StorageService();

  Tasbih? _selectedTasbih;
  bool _didResolveInitialSelection = false;
  bool _flowPrepared = false;
  List<String> _activeFlowIds = const <String>[];
  int _activeFlowIndex = 0;

  /// Sunnah context for the currently selected tasbih (provides Arabic text, etc.)
  Sunnah? _activeSunnah;

  /// Cached lookup: tasbihId → Sunnah (populated lazily)
  Map<String, Sunnah>? _sunnahByTasbihId;

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
              if (state is TasbihLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TasbihError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: AppTextStyles.body(color: Colors.white),
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
                    _selectedTasbih = state.tasbihs.firstWhere(
                      (t) => t.id == _selectedTasbih!.id,
                    );
                    final flowIdx = _activeFlowIds.indexOf(_selectedTasbih!.id);
                    if (flowIdx >= 0) {
                      _activeFlowIndex = flowIdx;
                    }
                  } catch (_) {
                    _selectedTasbih =
                        state.tasbihs.isNotEmpty ? state.tasbihs.first : null;
                  }
                }

                if (_selectedTasbih == null) {
                  return const Center(
                    child: Text(
                      'No Tasbihs found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Resolve the active sunnah for the selected tasbih
                _activeSunnah = _resolveSunnahForTasbih(_selectedTasbih!);

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    title: Text(
                      'Digital Tasbih',
                      style: AppTextStyles.h3(color: Colors.white),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => _showResetDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.list, color: Colors.white),
                        onPressed:
                            () => _showTasbihList(context, state.tasbihs),
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showTasbihList(context, state.tasbihs),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedTasbih!.name,
                                  style: AppTextStyles.h2(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ─── Arabic text display ───
                        if (_activeSunnah?.arabic != null) ...[
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _activeSunnah!.arabic!,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                        // ─── Transliteration ───
                        if (_activeSunnah?.transliteration != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _activeSunnah!.transliteration!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                color: Colors.white.withValues(alpha: 0.7),
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        // ─── English translation ───
                        if (_activeSunnah?.translation != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              '"${_activeSunnah!.translation!}"',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.small(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                        // ─── Recitation hint (fallback for non-sunnah tasbihs) ───
                        if (_activeSunnah?.arabic == null && _recitationHint(_selectedTasbih!) != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _recitationHint(_selectedTasbih!)!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.small(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),
                        GestureDetector(
                          onTap: () {
                            _onCounterTap(state.tasbihs);
                          },
                          child: CircularPercentIndicator(
                            radius: 120.0,
                            lineWidth: 15.0,
                            percent: (_selectedTasbih!.currentCount /
                                    _selectedTasbih!.targetCount)
                                .clamp(0.0, 1.0),
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_selectedTasbih!.currentCount}',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '/ ${_selectedTasbih!.targetCount}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            progressColor: AppColors.activeGlow,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                            animateFromLastPercent: true,
                            animationDuration: 100,
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (_isSequencedFlow) ...[
                          Text(
                            'Tasbih of Fatimah (RA) ${_activeFlowIndex + 1}/${_activeFlowIds.length}',
                            style: AppTextStyles.small(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Total Count',
                              '${_selectedTasbih!.totalCount}',
                            ),
                          ],
                        ),
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

  PrayerPeriod _prayerPeriodFromState(PrayerState state) {
    if (state is PrayerLoaded) {
      return state.prayerPeriod;
    }
    return PrayerPeriod.isha;
  }

  WeatherCondition _weatherConditionFromTheme(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.clear:
        return WeatherCondition.clear;
      case WeatherTheme.cloudy:
        return WeatherCondition.cloudy;
      case WeatherTheme.rain:
        return WeatherCondition.rain;
      case WeatherTheme.thunderstorm:
        return WeatherCondition.thunderstorm;
      case WeatherTheme.snow:
        return WeatherCondition.snow;
      case WeatherTheme.fog:
        return WeatherCondition.fog;
      case WeatherTheme.auto:
        return WeatherCondition.clear;
    }
  }

  int _cloudCoverageFromTheme(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.clear:
        return 0;
      case WeatherTheme.cloudy:
        return 90;
      case WeatherTheme.rain:
        return 100;
      case WeatherTheme.thunderstorm:
        return 100;
      case WeatherTheme.snow:
        return 100;
      case WeatherTheme.fog:
        return 40;
      case WeatherTheme.auto:
        return 0;
    }
  }

  bool get _isSequencedFlow => _activeFlowIds.isNotEmpty;

  void _prepareFlowIfNeeded(List<Tasbih> tasbihs) {
    if (_flowPrepared) return;
    _flowPrepared = true;

    if (widget.initialFlow == _flowFatimah) {
      _activeFlowIds = _fatimahSequence;
      _activeFlowIndex = 0;

      // Start a fresh guided cycle for Fatimah (RA) tasbih.
      for (final id in _activeFlowIds) {
        final item = _findTasbihById(tasbihs, id);
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
      final first = _findTasbihById(tasbihs, _activeFlowIds.first);
      if (first != null) return first;
    }

    final initialId = widget.initialTasbihId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      for (final tasbih in tasbihs) {
        if (tasbih.id.toLowerCase() == initialId.toLowerCase()) {
          return tasbih;
        }
      }
    }

    final query = widget.initialQuery?.toLowerCase().trim();
    if (query == null || query.isEmpty) {
      return null;
    }

    final mappedId = _mapQueryToTasbihId(query);
    if (mappedId != null) {
      for (final tasbih in tasbihs) {
        if (tasbih.id.toLowerCase() == mappedId) {
          return tasbih;
        }
      }
    }

    for (final tasbih in tasbihs) {
      final haystack = '${tasbih.id} ${tasbih.name}'.toLowerCase();
      if (haystack.contains(query)) {
        return tasbih;
      }
    }

    return null;
  }

  Tasbih? _findTasbihById(List<Tasbih> tasbihs, String id) {
    for (final tasbih in tasbihs) {
      if (tasbih.id == id) return tasbih;
    }
    return null;
  }

  /// Looks up the enriched [Sunnah] for the given tasbih, providing Arabic
  /// text, transliteration, translation, and repetitions.
  Sunnah? _resolveSunnahForTasbih(Tasbih tasbih) {
    // Fast path: if the widget was opened with a specific sunnah and the
    // tasbih ID matches, use it directly.
    if (widget.sourceSunnah?.tasbihId == tasbih.id) {
      return widget.sourceSunnah;
    }

    // Lazy-build a lookup map from all sunnahs that have a tasbihId.
    _sunnahByTasbihId ??= _buildSunnahLookup();
    return _sunnahByTasbihId![tasbih.id];
  }

  Map<String, Sunnah> _buildSunnahLookup() {
    try {
      final repo = context.read<SunnahRepository>();
      // getAllSunnahs is async but the repo caches data eagerly, so we
      // fire-and-forget and populate on next frame.  For the initial
      // build we use a synchronous approach via the cached list.
      final sunnahs = repo.getAllSunnahsSync();
      final map = <String, Sunnah>{};
      for (final s in sunnahs) {
        if (s.tasbihId != null && !map.containsKey(s.tasbihId)) {
          map[s.tasbihId!] = s;
        }
      }
      return map;
    } catch (_) {
      // Repository not available (e.g. opened standalone)
      return <String, Sunnah>{};
    }
  }

  void _onCounterTap(List<Tasbih> tasbihs) {
    if (_selectedTasbih == null) return;

    HapticFeedback.lightImpact();
    final selected = _selectedTasbih!;
    final newCount = selected.currentCount + 1;

    if (newCount % selected.targetCount == 0) {
      HapticFeedback.mediumImpact();
    }

    int displayCount;
    if (_isSequencedFlow) {
      displayCount = newCount > selected.targetCount ? selected.targetCount : newCount;
    } else {
      displayCount = newCount;
      if (displayCount > selected.targetCount) {
        displayCount = 1;
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

    if (_activeFlowIndex >= _activeFlowIds.length - 1) {
      setState(() {
        _activeFlowIds = const <String>[];
        _activeFlowIndex = 0;
      });
      _showAppSnackBar(
        message: 'Tasbih of Fatimah (RA) completed.',
        icon: Icons.check_circle_outline_rounded,
      );
      return;
    }

    final nextIndex = _activeFlowIndex + 1;
    final nextId = _activeFlowIds[nextIndex];
    final nextTasbih = _findTasbihById(tasbihs, nextId);
    if (nextTasbih == null) return;

    var preparedNext = nextTasbih;
    if (preparedNext.currentCount != 0) {
      preparedNext = preparedNext.copyWith(currentCount: 0, lastUpdated: DateTime.now());
      context.read<TasbihBloc>().add(UpdateTasbih(preparedNext));
    }

    setState(() {
      _activeFlowIndex = nextIndex;
      _selectedTasbih = preparedNext;
    });
  }

  String? _mapQueryToTasbihId(String query) {
    if (query.contains('fatimah')) return 'subhanallah';
    if (query.contains('morning')) return 'morning_azkar';
    if (query.contains('evening')) return 'evening_azkar';
    if (query.contains('before sleep') ||
        query.contains('sleep') ||
        query.contains('night')) {
      return 'before_sleep_azkar';
    }
    if (query.contains('subhan')) return 'subhanallah';
    if (query.contains('alhamdulillah')) return 'alhamdulillah';
    if (query.contains('allahu akbar') || query.contains('takbir')) {
      return 'allahuakbar';
    }
    if (query.contains('astaghfir')) return 'astaghfirullah';
    if (query.contains('la ilaha')) return 'la_ilaha_illallah';
    if (query.contains('salawat') || query.contains('durood')) return 'salawat';
    return null;
  }

  /// Returns a recitation instruction. Prefers enriched sunnah data;
  /// falls back to hardcoded hints for standalone-opened tasbihs.
  String? _recitationHint(Tasbih tasbih) {
    // Try sunnah description first (dynamic)
    final sunnah = _resolveSunnahForTasbih(tasbih);
    if (sunnah != null) {
      // If the sunnah has Arabic text, truncate the description since
      // Arabic+transliteration+translation are already shown.
      if (sunnah.arabic != null) return null;
      return sunnah.description;
    }

    // Hardcoded fallback for standalone use
    switch (tasbih.id) {
      case 'morning_azkar':
        return 'Recite: Ayat al-Kursi (1x), Ikhlas/Falaq/Nas (3x), and Sayyid al-Istighfar (1x).';
      case 'evening_azkar':
        return 'Recite: Ayat al-Kursi (1x), Ikhlas/Falaq/Nas (3x), and evening protection adhkar.';
      case 'before_sleep_azkar':
        return 'Before sleep: SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (34x).';
      case 'subhanallah':
        return 'Say: SubhanAllah.';
      case 'alhamdulillah':
        return 'Say: Alhamdulillah.';
      case 'allahuakbar':
        return 'Say: Allahu Akbar.';
      case 'astaghfirullah':
        return 'Say: Astaghfirullah.';
      case 'la_ilaha_illallah':
        return 'Say: La ilaha illallah.';
      case 'salawat':
        return 'Send salawat upon the Prophet ﷺ.';
      default:
        return null;
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2(color: AppColors.activeGlow)),
        Text(label, style: AppTextStyles.tiny(color: Colors.white70)),
      ],
    );
  }

  void _showTasbihList(BuildContext context, List<Tasbih> tasbihs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetCtx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text('Select Dhikr', style: AppTextStyles.h2(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // List
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: tasbihs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.06),
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
                                setState(() {
                                  _selectedTasbih = t;
                                  _activeSunnah = sunnah;
                                });
                                Navigator.pop(sheetCtx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                                          const SizedBox(height: 2),
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
                                      Icon(Icons.check_circle, color: AppColors.activeGlow, size: 20),
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
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 44, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text('Reset Counter?', style: AppTextStyles.h2(color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    'This will reset the current count to 0.',
                    style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dlgCtx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF121E3A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.activeGlow),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.small(
                    color: Colors.white.withValues(alpha: 0.93),
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
