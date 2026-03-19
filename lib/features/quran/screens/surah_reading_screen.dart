import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/common/premium_flowing_loader.dart';
import '../../../widgets/common/string_lights_overlay.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/repositories/quran_repository.dart';
import '../../../core/repositories/surah_info_local_repository.dart';
import '../../../core/repositories/quran_progress_repository.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../core/services/storage_service.dart';
import '../../../models/settings.dart';
import '../../../core/utils/islamic_day_utils.dart';
import '../../../models/verse.dart';
import '../../../models/surah.dart';
import '../../../models/quran_bookmark.dart';
import '../widgets/surah_info_modal.dart';
import '../bloc/quran_bloc.dart';

/// Reading screen for a surah – beautiful verse-by-verse with dynamic gradient
class SurahReadingScreen extends StatefulWidget {
  final int surahId;
  final String? surahName;
  final PrayerPeriod prayerPeriod;

  const SurahReadingScreen({
    super.key,
    required this.surahId,
    this.surahName,
    this.prayerPeriod = PrayerPeriod.isha,
  });

  @override
  State<SurahReadingScreen> createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Verse> _verses = [];
  bool _isLoading = true;
  String? _error;
  late QuranRepository _repository;
  final QuranProgressRepository _progressRepo = QuranProgressRepository();
  int _lastReadVerse = 1;
  int _initialReadVerse = 1;

  // Reading Settings
  bool _showTranslation = true;
  bool _showTransliteration = false;
  double _arabicFontSize = 32.0;
  double _translationFontSize = 16.0;
  String _selectedTranslation = 'Mustafa Khattab';

  final List<String> _availableTranslations = [
    'Mustafa Khattab',
    'Saheeh Intl',
    'Yusuf Ali',
  ];

  QuranScript _selectedScript = QuranScript.indopak;

  @override
  void initState() {
    super.initState();
    _repository = context.read<QuranRepository>();

    final settings = StorageService().getSettings();
    _showTranslation = settings.quranShowTranslation;
    _showTransliteration = settings.quranShowTransliteration;
    _arabicFontSize = settings.quranArabicFontSize;
    _translationFontSize = settings.quranTranslationFontSize;
    _selectedTranslation = settings.quranSelectedTranslation;
    _selectedScript = settings.quranSelectedScript;

    _loadVerses();
  }

  Future<void> _loadVerses() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final verses = await _repository.getVerses(
        widget.surahId,
        translationName: _selectedTranslation,
        scriptFieldName: _selectedScript.apiFieldName,
      );

      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;

          final quranState = context.read<QuranBloc>().state;
          if (quranState is QuranLoaded) {
            final bookmark = quranState.lastRead;
            if (bookmark != null && bookmark.surahId == widget.surahId) {
              _initialReadVerse = bookmark.verseNumber;
              _lastReadVerse = bookmark.verseNumber;
            } else {
              _initialReadVerse = 1;
              _lastReadVerse = 1;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_verses.isNotEmpty) {
      context.read<QuranBloc>().add(
        UpdateLastRead(
          surahId: widget.surahId,
          verseNumber: _lastReadVerse,
          surahName: widget.surahName,
        ),
      );

      final versesReadInSession = _lastReadVerse - _initialReadVerse + 1;
      if (versesReadInSession > 0) {
        _progressRepo.markVersesRead(versesReadInSession);
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onBookmarkVerse(Verse verse) {
    final bookmark = QuranBookmark(
      id: 'bm_${verse.verseKey}_${DateTime.now().millisecondsSinceEpoch}',
      surahId: verse.surahId,
      verseNumber: verse.verseNumber,
      surahName: widget.surahName,
      label: '${widget.surahName ?? 'Surah ${verse.surahId}'} : ${verse.verseNumber}',
      createdAt: DateTime.now(),
    );

    context.read<QuranBloc>().add(SaveBookmark(bookmark));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.spiritualGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: AppColors.spiritualGold, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bookmarked verse ${verse.verseNumber}',
                    style: AppTextStyles.small(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    HapticFeedback.mediumImpact();
  }

  void _showSettingsSheet(bool isSmallPhone) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _ReadingSettingsSheet(
        showTranslation: _showTranslation,
        showTransliteration: _showTransliteration,
        arabicFontSize: _arabicFontSize,
        translationFontSize: _translationFontSize,
        selectedTranslation: _selectedTranslation,
        availableTranslations: _availableTranslations,
        selectedScript: _selectedScript,
        isSmallPhone: isSmallPhone,
        onSettingsChanged: (translation, transliteration, arabicSize, translationSize, selectedTrans, script) {
          setState(() {
            _showTranslation = translation;
            _showTransliteration = transliteration;
            _arabicFontSize = arabicSize;
            _translationFontSize = translationSize;

            if (_selectedTranslation != selectedTrans) {
              _selectedTranslation = selectedTrans;
              _loadVerses();
            }

            if (_selectedScript != script) {
              _selectedScript = script;
              _loadVerses();
            }

            final currentSettings = StorageService().getSettings();
            StorageService().saveSettings(
              currentSettings.copyWith(
                quranShowTranslation: translation,
                quranShowTransliteration: transliteration,
                quranArabicFontSize: arabicSize,
                quranTranslationFontSize: translationSize,
                quranSelectedTranslation: selectedTrans,
                quranSelectedScript: script,
              ),
            );
          });
        },
      ),
    );
  }

  void _showSurahInfoModal(SurahInfoData info, bool isSmallPhone) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kToolbarHeight),
        child: SurahInfoModal(info: info),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = AppColors.getGradientForPeriod(PrayerPeriod.tahajjud);

    final size = MediaQuery.sizeOf(context);
    final bool isSmallPhone = size.width < 360;
    final double hPad = (size.width * 0.04).clamp(16.0, 24.0);

    Surah? surahDetails;
    final quranState = context.read<QuranBloc>().state;
    if (quranState is QuranLoaded) {
      surahDetails = quranState.surahs.where((s) => s.id == widget.surahId).firstOrNull;
    }

    final isMakki = surahDetails?.revelationPlace.toLowerCase() == 'makkah';

    final now = DateTime.now();
    final isRamadanMode = IslamicDayUtils.isRamadanDate(now);
    final settings = StorageService().getSettings();

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
        body: Stack(
          children: [
            // 1. Put the main content FIRST (at the back)
            if (!_isLoading)
              RawScrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                interactive: true,
                thickness: 3,
                radius: const Radius.circular(10),
                thumbColor: AppColors.spiritualGold.withValues(alpha: 0.7),
                crossAxisMargin: 2,
                child: _buildScrollView(isSmallPhone, hPad, isMakki, surahDetails),
              )
            else
              _buildScrollView(isSmallPhone, hPad, isMakki, surahDetails),

            // 2. Put the decoration LAST (at the front)
            if (isRamadanMode && settings.islamicEventsEnabled)
              Positioned(
                top: size.height * 0.02,
                left: 0,
                right: 0,
                height: size.height * 0.18,
                child: const IgnorePointer( // Added IgnorePointer so it doesn't block App Bar taps!
                  child: StringLightsOverlay(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollView(bool isSmallPhone, double hPad, bool isMakki, Surah? surahDetails) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [

        // 1. DYNAMIC SLIVER APP BAR
        SliverAppBar(
          pinned: true,
          expandedHeight: isSmallPhone ? 240.0 : 260.0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(48),
            ),
          ),
                    leadingWidth: 64,
                    leading: Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isSmallPhone ? 18 : 20),
                        ),
                      ),
                    ),
                    actions: [
                      if (SurahInfoLocalRepository().getInfo(widget.surahId) != null) ...[
                        GestureDetector(
                          onTap: () => _showSurahInfoModal(SurahInfoLocalRepository().getInfo(widget.surahId)!, isSmallPhone),
                          child: Container(
                            padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                            decoration: BoxDecoration(color: AppColors.spiritualGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.info_outline_rounded, color: AppColors.spiritualGold, size: isSmallPhone ? 18 : 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      GestureDetector(
                        onTap: () => _showSettingsSheet(isSmallPhone),
                        child: Container(
                          padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: Icon(Icons.tune_rounded, color: Colors.white, size: isSmallPhone ? 18 : 20),
                        ),
                      ),
                      SizedBox(width: hPad),
                    ],
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.2), // Dark glass tint for readability
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            titlePadding: const EdgeInsets.only(bottom: 16),
                            // Pinned Title (Only prominently visible when collapsed)
                            title: Text(
                                widget.surahName ?? 'Surah ${widget.surahId}',
                                style: AppTextStyles.h2(color: Colors.white).copyWith(
                                  fontSize: isSmallPhone ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                )
                            ),
                            // Expanded Background Details
                            background: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: MediaQuery.paddingOf(context).top + 20),
                                Text(
                                    surahDetails?.nameArabic ?? '',
                                    style: AppTextStyles.arabic(color: AppColors.spiritualGold, size: isSmallPhone ? 34 : 40)
                                ),
                                const SizedBox(height: 6),
                                Text(
                                    surahDetails?.nameTranslation ?? '',
                                    style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)).copyWith(
                                        fontSize: isSmallPhone ? 12 : 14
                                    )
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(
                                        opacity: 0.6,
                                        child: Text(isMakki ? '🕋' : '🕌', style: TextStyle(fontSize: isSmallPhone ? 12 : 14))
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                        isMakki ? 'Meccan' : 'Medinan',
                                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.8)).copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallPhone ? 10 : 12,
                                        )
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: CircleAvatar(radius: 2, backgroundColor: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    Text(
                                        'Surah ${surahDetails?.id ?? widget.surahId}',
                                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.8)).copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallPhone ? 10 : 12,
                                        )
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: CircleAvatar(radius: 2, backgroundColor: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    Text(
                                        '${surahDetails?.versesCount ?? _verses.length} Ayahs',
                                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.8)).copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallPhone ? 10 : 12,
                                        )
                                    ),
                                    if (surahDetails?.revelationOrder != null) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: CircleAvatar(radius: 2, backgroundColor: Colors.white.withValues(alpha: 0.4)),
                                      ),
                                      Text(
                                          'Rev. ${surahDetails!.revelationOrder}',
                                          style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.8)).copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isSmallPhone ? 10 : 12,
                                          )
                                      ),
                                    ],
                                  ],
                                ),
                                // Push contents up slightly to not collide with the Title
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Separated Bismillah
                  if (!_isLoading && _error == null && widget.surahId != 9 && widget.surahId != 1)
                    SliverToBoxAdapter(
                      child: _buildBismillah(isSmallPhone)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                    ),

                  // 3. Content / Loading State
                  if (_isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const PremiumFlowingLoader(size: 50.0, color: AppColors.spiritualGold),
                            const SizedBox(height: 24),
                            Text(
                              'Loading verses...',
                              style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w500).copyWith(letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('Failed to load verses', style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadVerses,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final verse = _verses[index];
                          if (verse.verseNumber > _lastReadVerse) {
                            _lastReadVerse = verse.verseNumber;
                          }
                          return _VerseCard(
                            verse: verse,
                            showTranslation: _showTranslation,
                            showTransliteration: _showTransliteration,
                            arabicFontSize: _arabicFontSize,
                            translationFontSize: _translationFontSize,
                            isSmallPhone: isSmallPhone,
                            horizontalPadding: hPad,
                            selectedScript: _selectedScript,
                            onBookmark: () => _onBookmarkVerse(verse),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 + (index.clamp(0, 10) * 30)), duration: 400.ms)
                              .slideY(begin: 0.05, delay: Duration(milliseconds: 50 + (index.clamp(0, 10) * 30)), curve: Curves.easeOutCubic);
                        }, childCount: _verses.length),
                      ),
                    ),
                ],
              );
  }

  Widget _buildBismillah(bool isSmallPhone) {
    return Padding(
      padding: EdgeInsets.only(top: isSmallPhone ? 20 : 28, bottom: isSmallPhone ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmallPhone ? 30 : 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.spiritualGold.withValues(alpha: 0.5)],
              ),
            ),
          ),
          SizedBox(width: isSmallPhone ? 12 : 16),
          Text(
            _selectedScript == QuranScript.indopak 
                ? 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ' 
                : 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            style: AppTextStyles.arabic(
              size: isSmallPhone ? 20 : 22,
              color: AppColors.spiritualGold.withValues(alpha: 0.9),
              script: _selectedScript,
            ).copyWith(height: 1.5),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(width: isSmallPhone ? 12 : 16),
          Container(
            width: isSmallPhone ? 30 : 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.spiritualGold.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VERSE CARD
// =============================================================================

class _VerseCard extends StatelessWidget {
  final Verse verse;
  final bool showTranslation;
  final bool showTransliteration;
  final double arabicFontSize;
  final double translationFontSize;
  final bool isSmallPhone;
  final double horizontalPadding;
  final QuranScript selectedScript;
  final VoidCallback onBookmark;

  const _VerseCard({
    required this.verse,
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.isSmallPhone,
    required this.horizontalPadding,
    required this.selectedScript,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onBookmark,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmallPhone ? 4 : 6),
        padding: EdgeInsets.all(isSmallPhone ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: isSmallPhone ? 32 : 36,
                  height: isSmallPhone ? 32 : 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.spiritualGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Text(
                    '${verse.verseNumber}',
                    style: GoogleFonts.inter(
                        fontSize: isSmallPhone ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.spiritualGold
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showVerseOptions(context, verse, onBookmark, isSmallPhone);
                  },
                  child: Container(
                    padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                    child: Icon(Icons.more_horiz_rounded, size: isSmallPhone ? 16 : 18, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallPhone ? 16 : 20),
            Text(
              verse.textUthmani,
              style: AppTextStyles.arabic(
                size: isSmallPhone ? arabicFontSize * 0.9 : arabicFontSize,
                color: Colors.white,
                script: selectedScript,
              ).copyWith(height: 2.0, letterSpacing: 0),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            if (showTransliteration && verse.transliterationText != null && verse.transliterationText!.isNotEmpty) ...[
              SizedBox(height: isSmallPhone ? 12 : 16),
              Text(
                verse.transliterationText!,
                style: GoogleFonts.inter(
                    fontSize: isSmallPhone ? translationFontSize - 2 : translationFontSize - 1,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: AppColors.spiritualGold.withValues(alpha: 0.8),
                    height: 1.5
                ),
                textAlign: TextAlign.left,
              ),
            ],
            if (showTranslation && verse.translationText != null && verse.translationText!.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.symmetric(vertical: isSmallPhone ? 12 : 16),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.1), Colors.transparent]),
                ),
              ),
              Text(
                verse.translationText!,
                style: GoogleFonts.inter(
                    fontSize: isSmallPhone ? translationFontSize * 0.9 : translationFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVerseOptions(BuildContext context, Verse verse, VoidCallback bookmarkCallback, bool isSmallPhone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetCtx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: EdgeInsets.fromLTRB(isSmallPhone ? 20 : 24, 12, isSmallPhone ? 20 : 24, isSmallPhone ? 32 : 40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: isSmallPhone ? 20 : 24),
                Text(
                  'Verse ${verse.verseNumber}',
                  style: AppTextStyles.h3(color: AppColors.spiritualGold).copyWith(fontSize: isSmallPhone ? 18 : null),
                ),
                SizedBox(height: isSmallPhone ? 12 : 16),
                _OptionsTile(
                  icon: Icons.bookmark_rounded,
                  title: 'Bookmark',
                  subtitle: 'Save to quick access',
                  color: AppColors.spiritualGold,
                  isSmallPhone: isSmallPhone,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(sheetCtx);
                    bookmarkCallback();
                  },
                ),
                const SizedBox(height: 8),
                _OptionsTile(
                  icon: Icons.copy_rounded,
                  title: 'Copy Arabic',
                  subtitle: 'Copy original text',
                  color: Colors.white,
                  isSmallPhone: isSmallPhone,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: verse.textUthmani));
                    Navigator.pop(sheetCtx);
                  },
                ),
                if (verse.translationText != null && verse.translationText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _OptionsTile(
                    icon: Icons.g_translate_rounded,
                    title: 'Copy Translation',
                    subtitle: 'Copy current translation',
                    color: Colors.white,
                    isSmallPhone: isSmallPhone,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: verse.translationText!));
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _OptionsTile(
                  icon: Icons.share_rounded,
                  title: 'Share Verse',
                  subtitle: 'Send to others',
                  color: Colors.white,
                  isSmallPhone: isSmallPhone,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(sheetCtx);
                    final shareText = '${verse.textUthmani}\n\n${verse.translationText ?? ''}\n— ${verse.translationName ?? 'Quran'} [${verse.surahId}:${verse.verseNumber}]';
                    try { await Share.share(shareText); } catch (e) { debugPrint('Error sharing: $e'); }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSmallPhone;
  final VoidCallback onTap;

  const _OptionsTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.isSmallPhone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 12 : 14, horizontal: isSmallPhone ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: isSmallPhone ? 16 : 18),
            ),
            SizedBox(width: isSmallPhone ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600).copyWith(fontSize: isSmallPhone ? 14 : null)),
                  Text(subtitle, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)).copyWith(fontSize: isSmallPhone ? 10 : null)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// READING SETTINGS BOTTOM SHEET
// =============================================================================

class _ReadingSettingsSheet extends StatefulWidget {
  final bool showTranslation;
  final bool showTransliteration;
  final double arabicFontSize;
  final double translationFontSize;
  final String selectedTranslation;
  final List<String> availableTranslations;
  final QuranScript selectedScript;
  final bool isSmallPhone;

  final void Function(bool translation, bool transliteration, double arabicSize, double translationSize, String selectedTrans, QuranScript script) onSettingsChanged;

  const _ReadingSettingsSheet({
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.selectedTranslation,
    required this.availableTranslations,
    required this.selectedScript,
    required this.isSmallPhone,
    required this.onSettingsChanged,
  });

  @override
  State<_ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<_ReadingSettingsSheet> {
  late bool _showTranslation;
  late bool _showTransliteration;
  late double _arabicFontSize;
  late double _translationFontSize;
  late String _selectedTranslation;
  late QuranScript _selectedScript;

  @override
  void initState() {
    super.initState();
    _showTranslation = widget.showTranslation;
    _showTransliteration = widget.showTransliteration;
    _arabicFontSize = widget.arabicFontSize;
    _translationFontSize = widget.translationFontSize;
    _selectedTranslation = widget.selectedTranslation;
    _selectedScript = widget.selectedScript;
  }

  void _notify() {
    widget.onSettingsChanged(_showTranslation, _showTransliteration, _arabicFontSize, _translationFontSize, _selectedTranslation, _selectedScript);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.fromLTRB(widget.isSmallPhone ? 20 : 24, 12, widget.isSmallPhone ? 20 : 24, widget.isSmallPhone ? 32 : 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: widget.isSmallPhone ? 20 : 24),
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: widget.isSmallPhone ? 18 : 20, color: AppColors.spiritualGold),
                  const SizedBox(width: 10),
                  Text('READING SETTINGS', style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: widget.isSmallPhone ? 10 : null)),
                ],
              ),
              SizedBox(height: widget.isSmallPhone ? 20 : 24),

              // ── Arabic Script Selector ──
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.font_download_rounded, size: widget.isSmallPhone ? 16 : 18, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text('Arabic Script', style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)).copyWith(fontSize: widget.isSmallPhone ? 10 : null)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: QuranScript.values.map((script) {
                    final isSelected = _selectedScript == script;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(script.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedScript = script);
                            _notify();
                          }
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: AppColors.spiritualGold.withValues(alpha: 0.2),
                        labelStyle: AppTextStyles.small(color: isSelected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7), weight: isSelected ? FontWeight.w600 : FontWeight.normal).copyWith(fontSize: widget.isSmallPhone ? 12 : null),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        showCheckmark: false,
                        padding: EdgeInsets.symmetric(horizontal: widget.isSmallPhone ? 10 : 12, vertical: widget.isSmallPhone ? 6 : 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: widget.isSmallPhone ? 16 : 20),

              // ── Toggles ──
              _SettingsToggle(
                icon: Icons.translate_rounded,
                label: 'Show Translation',
                subtitle: 'Display meanings in English',
                value: _showTranslation,
                isSmallPhone: widget.isSmallPhone,
                onChanged: (val) { setState(() => _showTranslation = val); _notify(); },
              ),
              SizedBox(height: widget.isSmallPhone ? 8 : 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                child: _showTranslation
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Text('Translation Source', style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)).copyWith(fontSize: widget.isSmallPhone ? 10 : null)),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: widget.availableTranslations.map((trans) {
                          final isSelected = _selectedTranslation == trans;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(trans),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTranslation = trans);
                                  _notify();
                                }
                              },
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              selectedColor: AppColors.spiritualGold.withValues(alpha: 0.2),
                              labelStyle: AppTextStyles.small(color: isSelected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7), weight: isSelected ? FontWeight.w600 : FontWeight.normal).copyWith(fontSize: widget.isSmallPhone ? 12 : null),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                ),
                              showCheckmark: false,
                              padding: EdgeInsets.symmetric(horizontal: widget.isSmallPhone ? 10 : 12, vertical: widget.isSmallPhone ? 6 : 8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: widget.isSmallPhone ? 12 : 16),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
              _SettingsToggle(
                icon: Icons.text_fields_rounded,
                label: 'Show Transliteration',
                subtitle: 'Romanized pronunciation guide',
                value: _showTransliteration,
                isSmallPhone: widget.isSmallPhone,
                onChanged: (val) { setState(() => _showTransliteration = val); _notify(); },
              ),
              SizedBox(height: widget.isSmallPhone ? 20 : 24),
              _FontSizeSlider(
                label: 'Arabic Font Size',
                sampleText: _selectedScript == QuranScript.indopak ? 'بِسۡمِ اللهِ' : 'بِسْمِ ٱللَّهِ',
                sampleStyle: AppTextStyles.arabic(
                  size: _arabicFontSize,
                  color: Colors.white,
                  script: _selectedScript,
                ).copyWith(height: 1.6),
                sampleDirection: TextDirection.rtl,
                value: _arabicFontSize,
                min: 24, max: 48,
                isSmallPhone: widget.isSmallPhone,
                onChanged: (val) { setState(() => _arabicFontSize = val); _notify(); },
              ),
              SizedBox(height: widget.isSmallPhone ? 12 : 16),
              if (_showTranslation)
                _FontSizeSlider(
                  label: 'Translation Font Size',
                  sampleText: 'In the name of Allah',
                  sampleStyle: GoogleFonts.inter(fontSize: _translationFontSize, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                  sampleDirection: TextDirection.ltr,
                  value: _translationFontSize,
                  min: 12, max: 24,
                  isSmallPhone: widget.isSmallPhone,
                  onChanged: (val) { setState(() => _translationFontSize = val); _notify(); },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool isSmallPhone;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({required this.icon, required this.label, required this.subtitle, required this.value, required this.isSmallPhone, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 14 : 16, vertical: isSmallPhone ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: isSmallPhone ? 18 : 20, color: Colors.white.withValues(alpha: 0.6)),
          SizedBox(width: isSmallPhone ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600).copyWith(fontSize: isSmallPhone ? 14 : null)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4)).copyWith(fontSize: isSmallPhone ? 10 : null)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) { HapticFeedback.selectionClick(); onChanged(val); },
            activeColor: Colors.white,
            activeTrackColor: AppColors.spiritualGold.withValues(alpha: 0.6),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  final String label;
  final String sampleText;
  final TextStyle sampleStyle;
  final TextDirection sampleDirection;
  final double value;
  final double min;
  final double max;
  final bool isSmallPhone;
  final ValueChanged<double> onChanged;

  const _FontSizeSlider({
    required this.label,
    required this.sampleText,
    required this.sampleStyle,
    required this.sampleDirection,
    required this.value,
    required this.min,
    required this.max,
    required this.isSmallPhone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w600)
                    .copyWith(fontSize: isSmallPhone ? 12 : null),
              ),
              Text(
                '${value.round()}',
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4))
                    .copyWith(fontSize: isSmallPhone ? 10 : null),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.spiritualGold.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: AppColors.spiritualGold,
            overlayColor: AppColors.spiritualGold.withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        Center(
          child: Text(
            sampleText,
            style: sampleStyle.copyWith(fontSize: isSmallPhone ? sampleStyle.fontSize! * 0.9 : sampleStyle.fontSize),
            textDirection: sampleDirection,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}