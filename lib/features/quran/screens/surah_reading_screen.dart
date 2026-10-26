import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/common/premium_flowing_loader.dart';
import '../../../widgets/common/festive_canopy.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/quran/quran_translations.dart';
import '../../../core/quran/transliterator.dart';
import '../../../core/repositories/quran_repository.dart';
import '../../../core/repositories/surah_info_local_repository.dart';
import '../../../core/repositories/quran_progress_repository.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../core/services/storage_service.dart';
import '../../../models/settings.dart';
import '../../../models/verse.dart';
import '../../../models/surah.dart';
import '../../../models/quran_bookmark.dart';
import '../sharing/verse_share.dart';
import '../sharing/verse_share_sheet.dart';
import '../widgets/jump_to_verse_sheet.dart';
import '../widgets/surah_info_modal.dart';
import '../../../widgets/common/glass_snackbar.dart';
import '../bloc/quran_bloc.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/app_backdrop_filter.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/glass_snackbar.dart';
import '../../../core/constants/radii.dart';
import '../../../widgets/common/kaaba_icon.dart';
import '../../../core/festive/festive_occasion.dart';

/// Reading screen for a surah – beautiful verse-by-verse with dynamic gradient
class SurahReadingScreen extends StatefulWidget {
  final int surahId;
  final String? surahName;
  final PrayerPeriod prayerPeriod;

  /// Ayah to scroll to and briefly highlight once verses load (from search,
  /// a juz, a bookmark or "continue reading").
  final int? initialVerse;

  /// Last ayah of a shared range; the whole range is highlighted.
  final int? initialVerseEnd;

  const SurahReadingScreen({
    super.key,
    required this.surahId,
    this.surahName,
    this.prayerPeriod = PrayerPeriod.isha,
    this.initialVerse,
    this.initialVerseEnd,
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
  // Captured up front: dispose() can't look up ancestors, and it's where the
  // last-read position gets saved.
  late QuranBloc _quranBloc;
  final QuranProgressRepository _progressRepo = QuranProgressRepository();
  int _lastReadVerse = 1;
  int _initialReadVerse = 1;

  bool _translationUnavailable = false;
  final Map<int, GlobalKey> _verseKeys = {};
  int? _highlightVerse;
  bool _jumping = false;

  /// Cache extent of the verse list; grows until the whole surah is laid out.
  double _layoutExtent = 1500;
  bool _fullyLaidOut = false;

  bool get _openedMidSurah => (widget.initialVerse ?? 1) > 1;

  // Reading Settings
  bool _showTranslation = true;
  bool _showTransliteration = false;
  double _arabicFontSize = 32.0;
  double _translationFontSize = 16.0;
  late TranslationOption _translation;
  TransliterationScript _translitScript = TransliterationScript.latin;

  QuranScript _selectedScript = QuranScript.indopak;

  @override
  void initState() {
    super.initState();
    _repository = context.read<QuranRepository>();
    _quranBloc = context.read<QuranBloc>();

    final settings = StorageService().getSettings();
    _showTranslation = settings.quranShowTranslation;
    _showTransliteration = settings.quranShowTransliteration;
    _arabicFontSize = settings.quranArabicFontSize;
    _translationFontSize = settings.quranTranslationFontSize;
    _translation = QuranTranslations.resolve(settings.quranSelectedTranslation);
    _translitScript = TransliterationScript.fromKey(settings.quranTransliterationScript);
    _selectedScript = settings.quranSelectedScript;

    final quranState = _quranBloc.state;
    final lastRead = quranState is QuranLoaded ? quranState.lastRead : null;
    final resumeVerse = lastRead != null && lastRead.surahId == widget.surahId ? lastRead.verseNumber : 1;
    _initialReadVerse = widget.initialVerse ?? resumeVerse;
    _lastReadVerse = _initialReadVerse;

    _loadVerses(scrollTo: widget.initialVerse);
  }

  Future<void> _loadVerses({int? scrollTo}) async {
    try {
      setState(() {
        _isLoading = _verses.isEmpty;
        _error = null;
      });

      // Translation and transliteration are always loaded, even when hidden,
      // so toggling them is instant and the translation gets saved offline.
      final content = await _repository.getSurahContent(
        widget.surahId,
        script: _selectedScript,
        translationId: _translation.id,
        transliteration: _translitScript,
      );

      if (!mounted) return;
      setState(() {
        _verses = content.verses;
        _translationUnavailable = !content.translationAvailable;
        _isLoading = false;
      });
      _fullyLaidOut = false;
      _growLayout();
      if (scrollTo != null && (scrollTo > 1 || widget.initialVerseEnd != null)) {
        _scrollToVerse(scrollTo);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateReadPosition());
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

  bool _isHighlighted(int verse) {
    final start = _highlightVerse;
    if (start == null) return false;
    final end = start == widget.initialVerse ? (widget.initialVerseEnd ?? start) : start;
    return verse >= start && verse <= end;
  }

  GlobalKey _keyFor(int verse) => _verseKeys.putIfAbsent(verse, () => GlobalKey());

  /// Brings an ayah into view below the pinned header.
  ///
  /// Every ayah is laid out once loaded (see [_buildScrollView]), so this
  /// normally lands on the first try; the estimate fallback below only
  /// matters in the frames before that first layout.
  Future<void> _scrollToVerse(int verse) async {
    if (verse < 1 || verse > _verses.length) return;
    _jumping = true;
    try {
      await _jumpToVerse(verse);
    } finally {
      _jumping = false;
      _updateReadPosition();
    }
  }

  /// Extends the laid-out region by a few screens per frame until the last
  /// ayah has been built, spreading the layout of a long surah over frames.
  void _growLayout() {
    if (_fullyLaidOut) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _verses.isEmpty) return;
      if (_verseKeys[_verses.length]?.currentContext != null) {
        _fullyLaidOut = true;
        return;
      }
      setState(() => _layoutExtent += 4000);
      _growLayout();
    });
  }

  /// Ayah numbers currently on screen below the pinned header.
  (int, int)? _visibleRange() {
    if (!mounted || _verses.isEmpty) return null;
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final bottom = MediaQuery.sizeOf(context).height;
    int? first;
    int? last;
    for (final v in _verses) {
      final box = _verseKeys[v.verseNumber]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y > bottom) break;
      if (y + box.size.height > top) {
        first ??= v.verseNumber;
        last = v.verseNumber;
      }
    }
    return first == null ? null : (first, last!);
  }

  /// Records how far the reader has got: the last ayah that has come on
  /// screen. Called when scrolling settles rather than as cards build,
  /// since the whole surah is built up front.
  void _updateReadPosition() {
    if (_jumping) return;
    final range = _visibleRange();
    if (range != null && range.$2 > _lastReadVerse) _lastReadVerse = range.$2;
  }

  Future<void> _openJumpSheet() async {
    final surah = _repository.surahById(widget.surahId);
    if (surah == null || _verses.isEmpty) return;
    final state = _quranBloc.state;
    final lastRead = state is QuranLoaded && state.lastRead?.surahId == widget.surahId
        ? state.lastRead!.verseNumber
        : null;
    final bookmarks = state is QuranLoaded
        ? (state.bookmarks.where((b) => b.surahId == widget.surahId).map((b) => b.verseNumber).toSet().toList()..sort())
        : <int>[];

    final target = await showJumpToVerseSheet(
      context,
      surah: surah,
      surahs: _repository.surahs,
      verses: _verses,
      currentVerse: _visibleRange()?.$1 ?? 1,
      lastReadVerse: lastRead,
      bookmarkedVerses: bookmarks,
    );
    if (!mounted || target == null) return;
    switch (target) {
      case JumpToAyah(:final verse):
        _scrollToVerse(verse);
      case JumpToSurah(:final surah, :final verse):
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SurahReadingScreen(
            surahId: surah,
            surahName: _repository.surahById(surah)?.nameTransliteration,
            prayerPeriod: widget.prayerPeriod,
            initialVerse: verse,
          ),
        ));
    }
  }

  Future<void> _jumpToVerse(int verse) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;

      final ctx = _verseKeys[verse]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(ctx, alignment: 0, duration: Duration.zero);
        if (!mounted) return;
        final pinned = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
        final pos = _scrollController.position;
        _scrollController.jumpTo((pos.pixels - pinned).clamp(pos.minScrollExtent, pos.maxScrollExtent));
        setState(() => _highlightVerse = verse);
        Future.delayed(Duration(milliseconds: widget.initialVerseEnd != null ? 3200 : 2200), () {
          if (mounted && _highlightVerse == verse) setState(() => _highlightVerse = null);
        });
        return;
      }

      // Estimate from built cards: average height and nearest built verse.
      final built = <int, RenderBox>{};
      _verseKeys.forEach((v, k) {
        final box = k.currentContext?.findRenderObject();
        if (box is RenderBox && box.hasSize) built[v] = box;
      });
      final pos = _scrollController.position;
      if (built.isEmpty) {
        _scrollController.jumpTo((pos.pixels + pos.viewportDimension).clamp(0, pos.maxScrollExtent));
        continue;
      }
      final avg = built.values.map((b) => b.size.height).reduce((a, b) => a + b) / built.length + 12;
      final nearest = built.keys.reduce((a, b) => (a - verse).abs() < (b - verse).abs() ? a : b);
      final delta = (verse - nearest) * avg;
      _scrollController.jumpTo((pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    }
  }

  @override
  void dispose() {
    if (_verses.isNotEmpty) {
      _quranBloc.add(
        UpdateLastRead(
          surahId: widget.surahId,
          verseNumber: _lastReadVerse,
          surahName: widget.surahName ?? _repository.surahById(widget.surahId)?.nameTransliteration,
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

  // ── Multi-select & sharing ──

  final Set<int> _selected = {};

  void _toggleSelect(int verse) {
    setState(() {
      if (!_selected.remove(verse)) _selected.add(verse);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  List<Verse> get _selectedVerses =>
      _verses.where((v) => _selected.contains(v.verseNumber)).toList();

  void _share(List<Verse> verses) {
    final surah = _repository.surahById(widget.surahId);
    if (surah == null || verses.isEmpty) return;
    showVerseShareSheet(
      context,
      share: VerseShare(surah: surah, verses: verses),
      script: _selectedScript,
      includeTranslation: _showTranslation,
      includeTransliteration: _showTransliteration,
    );
  }

  Future<void> _copySelection() async {
    await _copyVerses(_selectedVerses);
    _clearSelection();
  }

  Widget _buildSelectionBar(bool isSmallPhone) {
    final surah = _repository.surahById(widget.surahId);
    final reference = surah == null || _selected.isEmpty
        ? ''
        : VerseShare(surah: surah, verses: _selectedVerses).reference;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151A2C).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.25), width: 0.6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Clear selection',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              HapticService().light();
              _clearSelection();
            },
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected.length == 1 ? '1 ayah' : '${_selected.length} ayahs',
                  style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600),
                ),
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: Icon(Icons.copy_rounded, color: Colors.white.withValues(alpha: 0.85), size: 20),
            onPressed: _copySelection,
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () => _share(_selectedVerses),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spiritualGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 14 : 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  List<QuranBookmark> _bookmarksFor(int verse) {
    final state = _quranBloc.state;
    if (state is! QuranLoaded) return const [];
    return state.bookmarks.where((b) => b.surahId == widget.surahId && b.verseNumber == verse).toList();
  }

  void _toggleBookmark(Verse verse) {
    final existing = _bookmarksFor(verse.verseNumber);
    if (existing.isEmpty) {
      _onBookmarkVerse(verse);
      return;
    }
    for (final b in existing) {
      _quranBloc.add(DeleteBookmark(b.id));
    }
    HapticService().light();
    GlassSnackBar.show(context, message: 'Removed bookmark for ayah ${verse.verseNumber}', icon: Icons.bookmark_remove_rounded);
  }

  Future<void> _copyVerses(List<Verse> verses) async {
    final surah = _repository.surahById(widget.surahId);
    if (surah == null || verses.isEmpty) return;
    final share = VerseShare(surah: surah, verses: verses);
    await Clipboard.setData(ClipboardData(
      text: share.toText(translation: _showTranslation, transliteration: _showTransliteration),
    ));
    HapticService().light();
    if (!mounted) return;
    GlassSnackBar.show(context, message: 'Copied ${share.title}', icon: Icons.check_rounded);
  }

  /// The ⋯ sheet: which ayah, then one row of actions.
  void _showVerseActions(Verse verse, bool isSmallPhone) {
    final surah = _repository.surahById(widget.surahId);
    final bookmarked = _bookmarksFor(verse.verseNumber).isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetCtx) {
        void run(VoidCallback action) {
          Navigator.pop(sheetCtx);
          action();
        }

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(sheetCtx).bottom),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.spiritualGold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.25), width: 0.5),
                        ),
                        child: Text(
                          '${verse.verseNumber}',
                          style: AppTextStyles.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.spiritualGold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${surah?.nameTransliteration ?? 'Surah ${widget.surahId}'} ${verse.verseKey}',
                              style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600),
                            ),
                            Text(
                              'Juz ${verse.juz} · Ayah ${verse.verseNumber} of ${surah?.versesCount ?? _verses.length}',
                              style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _VerseAction(
                        icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        label: bookmarked ? 'Saved' : 'Bookmark',
                        active: bookmarked,
                        onTap: () => run(() => _toggleBookmark(verse)),
                      ),
                      _VerseAction(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: () => run(() => _copyVerses([verse])),
                      ),
                      _VerseAction(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onTap: () => run(() => _share([verse])),
                      ),
                      _VerseAction(
                        icon: Icons.checklist_rounded,
                        label: 'Select',
                        onTap: () => run(() {
                          HapticService().selection();
                          _toggleSelect(verse.verseNumber);
                        }),
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

    GlassSnackBar.show(
      context,
      message: 'Bookmarked verse ${verse.verseNumber}',
      icon: Icons.bookmark_rounded,
      duration: const Duration(seconds: 2),
    );

    HapticService().medium();
  }

  void _showSettingsSheet(bool isSmallPhone) {
    HapticService().light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _ReadingSettingsSheet(
        prefs: _ReadingPrefs(
          showTranslation: _showTranslation,
          showTransliteration: _showTransliteration,
          arabicFontSize: _arabicFontSize,
          translationFontSize: _translationFontSize,
          translation: _translation,
          transliterationScript: _translitScript,
          script: _selectedScript,
        ),
        repository: _repository,
        isSmallPhone: isSmallPhone,
        onChanged: (p) {
          final reload = p.translation.id != _translation.id ||
              p.script != _selectedScript ||
              p.transliterationScript != _translitScript;
          setState(() {
            _showTranslation = p.showTranslation;
            _showTransliteration = p.showTransliteration;
            _arabicFontSize = p.arabicFontSize;
            _translationFontSize = p.translationFontSize;
            _translation = p.translation;
            _translitScript = p.transliterationScript;
            _selectedScript = p.script;
          });
          if (reload) _loadVerses();

          final currentSettings = StorageService().getSettings();
          StorageService().saveSettings(
            currentSettings.copyWith(
              quranShowTranslation: p.showTranslation,
              quranShowTransliteration: p.showTransliteration,
              quranArabicFontSize: p.arabicFontSize,
              quranTranslationFontSize: p.translationFontSize,
              quranSelectedTranslation: '${p.translation.id}',
              quranSelectedScript: p.script,
              quranTransliterationScript: p.transliterationScript.key,
            ),
          );
        },
      ),
    );
  }

  void _showSurahInfoModal(SurahInfoData info, bool isSmallPhone) {
    HapticService().light();
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

    final Surah? surahDetails = _repository.surahById(widget.surahId);

    final isMakki = surahDetails?.revelationPlace.toLowerCase() == 'makkah';

    final settings = StorageService().getSettings();
    // Same occasions as the rest of the app (Ramadan, the Eids, Arafah).
    final occasion = FestiveOccasion.today(enabled: settings.islamicEventsEnabled);

    // Back clears a selection before it leaves the surah.
    return PopScope(
      canPop: _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Container(
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
            if (occasion != null)
              Positioned(
                top: size.height * 0.02,
                left: 0,
                right: 0,
                height: size.height * 0.18,
                child: FestiveCanopy(mood: occasion.mood),
              ),

            // 3. Multi-select actions
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: hPad,
              right: hPad,
              bottom: _selected.isEmpty ? -120 : MediaQuery.paddingOf(context).bottom + 16,
              child: _buildSelectionBar(isSmallPhone),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildScrollView(bool isSmallPhone, double hPad, bool isMakki, Surah? surahDetails) {
    // The surah is already on the device, so every ayah gets laid out, not
    // just those near the screen: the scroll length is then exact, so
    // dragging the scrollbar and jumping to an ayah land precisely instead of
    // the list building, and resizing, as it goes. The cache extent grows a
    // few screens per frame after the first paint (see [_growLayout]); doing
    // it in one frame took ~300ms for Al-Baqarah on a mid-range phone.
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _updateReadPosition();
        return false;
      },
      child: CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      cacheExtent: _isLoading ? null : _layoutExtent,
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
                      child: Pressable(
                        pressedScale: 0.88,
                        haptic: PressableHaptic.none,
                        onTap: () {
                          HapticService().light();
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
                        Pressable(
                          pressedScale: 0.88,
                          onTap: () => _showSurahInfoModal(SurahInfoLocalRepository().getInfo(widget.surahId)!, isSmallPhone),
                          child: Container(
                            padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                            decoration: BoxDecoration(color: AppColors.spiritualGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.info_outline_rounded, color: AppColors.spiritualGold, size: isSmallPhone ? 18 : 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Pressable(
                        pressedScale: 0.88,
                        onTap: () => _showSettingsSheet(isSmallPhone),
                        child: Container(
                          padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: Icon(Icons.tune_rounded, color: Colors.white, size: isSmallPhone ? 18 : 20),
                        ),
                      ),
                      SizedBox(width: hPad),
                    ],
                    // This bar is PINNED, so it stays on screen while verses
                    // scroll beneath it — meaning its BackdropFilter re-blurs a
                    // full-width region on every single scroll frame, and blur
                    // cost scales with sigma. Unlike the flat surfaces on the
                    // surah list, real text moves behind this one, so the glass
                    // effect is actually visible here and worth keeping; sigma
                    // is dropped from 20 to 8 and the tint is deepened slightly
                    // to preserve legibility, which keeps the look at a
                    // fraction of the per-frame cost.
                    flexibleSpace: ClipRect(
                      child: AppBackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.28), // Dark glass tint for readability
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            titlePadding: const EdgeInsets.only(bottom: 16),
                            // Pinned Title (Only prominently visible when collapsed)
                            // Tapping the title opens Go to. The faint chevron
                            // is the only hint, so it's there for the curious
                            // without adding another button to the bar.
                            title: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _isLoading ? null : _openJumpSheet,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      widget.surahName ?? surahDetails?.nameTransliteration ?? 'Surah ${widget.surahId}',
                                      style: AppTextStyles.h2(color: Colors.white).copyWith(
                                        fontSize: isSmallPhone ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      )
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.expand_more_rounded, size: isSmallPhone ? 16 : 18, color: Colors.white.withValues(alpha: 0.4)),
                                ],
                              ),
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
                                    isMakki
                                        ? KaabaIcon(size: isSmallPhone ? 13 : 15)
                                        : Icon(
                                            Icons.mosque_rounded,
                                            size: isSmallPhone ? 13 : 15,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                    const SizedBox(width: 6),
                                    Text(
                                        // Matches the surah list screen's badge.
                                        isMakki ? 'Makki' : 'Madani',
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
                            Text('Couldn\'t load this surah', style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 6),
                            Text(
                              'It downloads once, then stays on your device.\nCheck your connection and try again.',
                              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.45)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadVerses,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (_showTranslation && _translationUnavailable)
                      SliverToBoxAdapter(child: _buildTranslationOfflineNotice(hPad)),
                    SliverPadding(
                      // Room for the selection bar so the last ayah stays reachable.
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + (_selected.isEmpty ? 32 : 110)),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final verse = _verses[index];
                          final card = _VerseCard(
                            key: _keyFor(verse.verseNumber),
                            verse: verse,
                            highlighted: _isHighlighted(verse.verseNumber),
                            translationRtl: _translation.isRtl,
                            transliterationScript: _translitScript,
                            showTranslation: _showTranslation,
                            showTransliteration: _showTransliteration,
                            arabicFontSize: _arabicFontSize,
                            translationFontSize: _translationFontSize,
                            isSmallPhone: isSmallPhone,
                            horizontalPadding: hPad,
                            selectedScript: _selectedScript,
                            onMore: () => _showVerseActions(verse, isSmallPhone),
                            selected: _selected.contains(verse.verseNumber),
                            selecting: _selected.isNotEmpty,
                            onToggleSelect: () => _toggleSelect(verse.verseNumber),
                            onShare: () => _share([verse]),
                          );
                          // The entrance stagger plays once, for the first
                          // screenful when a surah opens from the top. Cards
                          // further down are already laid out and simply
                          // there when scrolled to; fading them in made a
                          // saved surah look like it was still loading.
                          if (_openedMidSurah || index > 5) return card;
                          return card
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 + (index.clamp(0, 10) * 30)), duration: 400.ms)
                              .slideY(begin: 0.05, delay: Duration(milliseconds: 50 + (index.clamp(0, 10) * 30)), curve: Curves.easeOutCubic);
                        }, childCount: _verses.length),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }

  Widget _buildTranslationOfflineNotice(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_translation.name} isn\'t saved on this device yet. It will download when you\'re online.',
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            TextButton(
              onPressed: _loadVerses,
              style: TextButton.styleFrom(foregroundColor: AppColors.spiritualGold, visualDensity: VisualDensity.compact),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
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

  /// Opens the ayah's action sheet (the ⋯ button).
  final VoidCallback onMore;
  final bool highlighted;
  final bool translationRtl;
  final TransliterationScript transliterationScript;

  /// Multi-select: [selecting] is true while any ayah is selected; taps then
  /// toggle instead of doing nothing.
  final bool selected;
  final bool selecting;
  final VoidCallback onToggleSelect;
  final VoidCallback onShare;

  const _VerseCard({
    super.key,
    required this.verse,
    required this.onToggleSelect,
    required this.onShare,
    this.selected = false,
    this.selecting = false,
    this.highlighted = false,
    this.translationRtl = false,
    this.transliterationScript = TransliterationScript.latin,
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.isSmallPhone,
    required this.horizontalPadding,
    required this.selectedScript,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlighted || selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        HapticService().medium();
        onToggleSelect();
      },
      onTap: selecting
          ? () {
              HapticService().selection();
              onToggleSelect();
            }
          : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: selecting ? 180 : 500),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmallPhone ? 4 : 6),
        padding: EdgeInsets.all(isSmallPhone ? 16 : 20),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.spiritualGold.withValues(alpha: selected ? 0.14 : 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent
                ? AppColors.spiritualGold.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
            width: accent ? 1 : 0.5,
          ),
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
                    style: AppTextStyles.inter(
                        fontSize: isSmallPhone ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.spiritualGold
                    ),
                  ),
                ),
                const Spacer(),
                if (selecting)
                  Padding(
                    padding: EdgeInsets.all(isSmallPhone ? 4 : 6),
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: isSmallPhone ? 22 : 24,
                      color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.35),
                    ),
                  )
                else
                  Pressable(
                    pressedScale: 0.88,
                    haptic: PressableHaptic.none,
                    onTap: () {
                      HapticService().light();
                      onMore();
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
                // Inter has no Devanagari/Bengali glyphs, so those fall back
                // to the system font; italics only suit the Latin script.
                style: GoogleFonts.inter(
                    fontSize: isSmallPhone ? translationFontSize - 2 : translationFontSize - 1,
                    fontWeight: FontWeight.w400,
                    fontStyle: transliterationScript == TransliterationScript.latin ? FontStyle.italic : FontStyle.normal,
                    color: AppColors.spiritualGold.withValues(alpha: 0.8),
                    height: transliterationScript == TransliterationScript.latin ? 1.5 : 1.7
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
                style: AppTextStyles.inter(
                    fontSize: isSmallPhone ? translationFontSize * 0.9 : translationFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: translationRtl ? 1.9 : 1.6
                ),
                textAlign: translationRtl ? TextAlign.right : TextAlign.left,
                textDirection: translationRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerseAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _VerseAction({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.spiritualGold : Colors.white;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.spiritualGold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? AppColors.spiritualGold.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(label, style: AppTextStyles.tiny(color: color.withValues(alpha: 0.85)).copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// READING SETTINGS BOTTOM SHEET
// =============================================================================

class _ReadingPrefs {
  final bool showTranslation;
  final bool showTransliteration;
  final double arabicFontSize;
  final double translationFontSize;
  final TranslationOption translation;
  final TransliterationScript transliterationScript;
  final QuranScript script;

  const _ReadingPrefs({
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.translation,
    required this.transliterationScript,
    required this.script,
  });

  _ReadingPrefs copyWith({
    bool? showTranslation,
    bool? showTransliteration,
    double? arabicFontSize,
    double? translationFontSize,
    TranslationOption? translation,
    TransliterationScript? transliterationScript,
    QuranScript? script,
  }) {
    return _ReadingPrefs(
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      translation: translation ?? this.translation,
      transliterationScript: transliterationScript ?? this.transliterationScript,
      script: script ?? this.script,
    );
  }
}

class _ReadingSettingsSheet extends StatefulWidget {
  final _ReadingPrefs prefs;
  final QuranRepository repository;
  final bool isSmallPhone;
  final ValueChanged<_ReadingPrefs> onChanged;

  const _ReadingSettingsSheet({
    required this.prefs,
    required this.repository,
    required this.isSmallPhone,
    required this.onChanged,
  });

  @override
  State<_ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<_ReadingSettingsSheet> {
  late _ReadingPrefs _p;
  late String _language;
  Set<int> _savedTranslations = {};
  int _savedSurahs = 0;
  String? _downloadError;

  QuranRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    _p = widget.prefs;
    _language = _p.translation.language;
    _repo.activeDownloads.addListener(_refreshOfflineState);
    _refreshOfflineState();
  }

  @override
  void dispose() {
    _repo.activeDownloads.removeListener(_refreshOfflineState);
    super.dispose();
  }

  Future<void> _refreshOfflineState() async {
    final saved = <int>{};
    for (final t in QuranTranslations.all) {
      if (await _repo.isTranslationDownloaded(t.id)) saved.add(t.id);
    }
    final surahs = await _repo.downloadedSurahs(_p.script);
    if (!mounted) return;
    setState(() {
      _savedTranslations = saved;
      _savedSurahs = surahs.length;
    });
  }

  void _update(_ReadingPrefs next) {
    setState(() => _p = next);
    widget.onChanged(next);
  }

  void _selectTranslation(TranslationOption t) {
    HapticService().selection();
    _update(_p.copyWith(translation: t));
    _startDownload(() => _repo.downloadTranslation(t.id));
  }

  void _startDownload(Future<void> Function() run) {
    setState(() => _downloadError = null);
    run().catchError((_) {
      if (mounted) setState(() => _downloadError = 'Download failed. Check your connection and try again.');
    }).whenComplete(_refreshOfflineState);
  }

  bool _isDownloading(String label) => _repo.activeDownloads.value.contains(label);

  @override
  Widget build(BuildContext context) {
    final small = widget.isSmallPhone;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      child: AppBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        fallbackTint: AppBackdropFilter.sheetTint,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(small ? 20 : 24, 12, small ? 20 : 24, (small ? 32 : 40) + MediaQuery.paddingOf(context).bottom),
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
                SizedBox(height: small ? 20 : 24),
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: small ? 18 : 20, color: AppColors.spiritualGold),
                    const SizedBox(width: 10),
                    Text('READING SETTINGS', style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: small ? 10 : null)),
                  ],
                ),
                SizedBox(height: small ? 20 : 24),

                // ── Arabic Script ──
                _SheetLabel(icon: Icons.font_download_rounded, text: 'Arabic Script', isSmallPhone: small),
                _ChipRow(
                  isSmallPhone: small,
                  children: [
                    for (final script in QuranScript.values)
                      _SheetChip(
                        label: script.displayName,
                        selected: _p.script == script,
                        isSmallPhone: small,
                        onTap: () {
                          HapticService().selection();
                          _update(_p.copyWith(script: script));
                          _refreshOfflineState();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _OfflineStatusRow(
                  icon: _savedSurahs == 114 ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined,
                  text: _savedSurahs == 114
                      ? 'Whole Quran saved for offline reading'
                      : '$_savedSurahs of 114 surahs saved · each surah is saved when first opened',
                  busy: _isDownloading('arabic_${_p.script.cacheKey}'),
                  actionLabel: _savedSurahs == 114 ? null : 'Save all',
                  onAction: () => _startDownload(() => _repo.downloadQuran(_p.script)),
                  done: _savedSurahs == 114,
                ),
                SizedBox(height: small ? 16 : 20),

                // ── Translation ──
                _SettingsToggle(
                  icon: Icons.translate_rounded,
                  label: 'Show Translation',
                  subtitle: 'Meaning of each ayah',
                  value: _p.showTranslation,
                  isSmallPhone: small,
                  onChanged: (val) => _update(_p.copyWith(showTranslation: val)),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: !_p.showTranslation
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _SheetLabel(icon: Icons.language_rounded, text: 'Language', isSmallPhone: small),
                            _ChipRow(
                              isSmallPhone: small,
                              children: [
                                for (final lang in QuranTranslations.languages)
                                  _SheetChip(
                                    label: lang,
                                    selected: _language == lang,
                                    isSmallPhone: small,
                                    onTap: () {
                                      HapticService().selection();
                                      setState(() => _language = lang);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SheetLabel(icon: Icons.person_outline_rounded, text: 'Translator', isSmallPhone: small),
                            _ChipRow(
                              isSmallPhone: small,
                              children: [
                                for (final t in QuranTranslations.forLanguage(_language))
                                  _SheetChip(
                                    label: t.name,
                                    selected: _p.translation.id == t.id,
                                    isSmallPhone: small,
                                    trailing: _savedTranslations.contains(t.id)
                                        ? Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.spiritualGold.withValues(alpha: 0.8))
                                        : null,
                                    onTap: () => _selectTranslation(t),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _OfflineStatusRow(
                              icon: _savedTranslations.contains(_p.translation.id)
                                  ? Icons.offline_pin_rounded
                                  : Icons.cloud_download_outlined,
                              text: _savedTranslations.contains(_p.translation.id)
                                  ? '${_p.translation.name} saved for offline reading'
                                  : _isDownloading('translation_${_p.translation.id}')
                                      ? 'Saving ${_p.translation.name} for offline reading…'
                                      : '${_p.translation.name} will be saved when you\'re online',
                              busy: _isDownloading('translation_${_p.translation.id}'),
                              actionLabel: _savedTranslations.contains(_p.translation.id) ? null : 'Save now',
                              onAction: () => _startDownload(() => _repo.downloadTranslation(_p.translation.id)),
                              done: _savedTranslations.contains(_p.translation.id),
                            ),
                          ],
                        ),
                ),
                if (_downloadError != null) ...[
                  const SizedBox(height: 8),
                  Text(_downloadError!, style: AppTextStyles.tiny(color: AppColors.statusMissed)),
                ],
                SizedBox(height: small ? 12 : 16),

                // ── Transliteration ──
                _SettingsToggle(
                  icon: Icons.text_fields_rounded,
                  label: 'Show Transliteration',
                  subtitle: 'Pronunciation guide · works offline',
                  value: _p.showTransliteration,
                  isSmallPhone: small,
                  onChanged: (val) => _update(_p.copyWith(showTransliteration: val)),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: !_p.showTransliteration
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _ChipRow(
                            isSmallPhone: small,
                            children: [
                              for (final script in TransliterationScript.values)
                                _SheetChip(
                                  label: script.label,
                                  selected: _p.transliterationScript == script,
                                  isSmallPhone: small,
                                  onTap: () {
                                    HapticService().selection();
                                    _update(_p.copyWith(transliterationScript: script));
                                  },
                                ),
                            ],
                          ),
                        ),
                ),
                SizedBox(height: small ? 20 : 24),

                _FontSizeSlider(
                  label: 'Arabic Font Size',
                  sampleText: _p.script == QuranScript.indopak ? 'بِسۡمِ اللهِ' : 'بِسْمِ ٱللَّهِ',
                  sampleStyle: AppTextStyles.arabic(
                    size: _p.arabicFontSize,
                    color: Colors.white,
                    script: _p.script,
                  ).copyWith(height: 1.6),
                  sampleDirection: TextDirection.rtl,
                  value: _p.arabicFontSize,
                  min: 24, max: 48,
                  isSmallPhone: small,
                  onChanged: (val) => _update(_p.copyWith(arabicFontSize: val)),
                ),
                SizedBox(height: small ? 12 : 16),
                if (_p.showTranslation || _p.showTransliteration)
                  _FontSizeSlider(
                    label: 'Translation Font Size',
                    sampleText: 'In the name of Allah',
                    sampleStyle: AppTextStyles.inter(fontSize: _p.translationFontSize, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                    sampleDirection: TextDirection.ltr,
                    value: _p.translationFontSize,
                    min: 12, max: 24,
                    isSmallPhone: small,
                    onChanged: (val) => _update(_p.copyWith(translationFontSize: val)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSmallPhone;

  const _SheetLabel({required this.icon, required this.text, required this.isSmallPhone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: isSmallPhone ? 16 : 18, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)).copyWith(fontSize: isSmallPhone ? 10 : null)),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  final bool isSmallPhone;

  const _ChipRow({required this.children, required this.isSmallPhone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final c in children) Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isSmallPhone;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SheetChip({
    required this.label,
    required this.selected,
    required this.isSmallPhone,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: AppColors.spiritualGold.withValues(alpha: 0.2),
      labelStyle: AppTextStyles.small(
        color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7),
        weight: selected ? FontWeight.w600 : FontWeight.normal,
      ).copyWith(fontSize: isSmallPhone ? 12 : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
      padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 10 : 12, vertical: isSmallPhone ? 6 : 8),
    );
  }
}

class _OfflineStatusRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool busy;
  final bool done;
  final String? actionLabel;
  final VoidCallback onAction;

  const _OfflineStatusRow({
    required this.icon,
    required this.text,
    required this.busy,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.spiritualGold.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          if (busy)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.spiritualGold),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.tiny(color: color))),
          if (actionLabel != null && !busy)
            TextButton(
              onPressed: () {
                HapticService().light();
                onAction();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.spiritualGold,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(actionLabel!),
            ),
        ],
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
            onChanged: (val) { HapticService().selection(); onChanged(val); },
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