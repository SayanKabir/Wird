import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wird2/widgets/common/premium_flowing_loader.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/quran/quran_meta.dart';
import '../../../core/quran/quran_translations.dart';
import '../../../core/repositories/quran_repository.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../core/services/quran_api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/home/bloc/prayer_bloc.dart';
import '../../../models/quran_bookmark.dart';
import '../../../models/surah.dart';
import '../bloc/quran_bloc.dart';
import 'surah_reading_screen.dart';
import '../../../widgets/common/page_header.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/app_route.dart';

enum _QuranTab { surah, juz, revelation, saved }

enum _SurahFilter { all, makki, madani, offline }

enum _SurahSort { mushaf, longest, shortest, name }

extension on _QuranTab {
  String get label => switch (this) {
        _QuranTab.surah => 'Surah',
        _QuranTab.juz => 'Juz',
        _QuranTab.revelation => 'Revelation',
        _QuranTab.saved => 'Saved',
      };
}

extension on _SurahFilter {
  String get label => switch (this) {
        _SurahFilter.all => 'All',
        _SurahFilter.makki => 'Makki',
        _SurahFilter.madani => 'Madani',
        _SurahFilter.offline => 'Offline',
      };
}

extension on _SurahSort {
  String get label => switch (this) {
        _SurahSort.mushaf => 'Mushaf order',
        _SurahSort.longest => 'Most ayahs',
        _SurahSort.shortest => 'Fewest ayahs',
        _SurahSort.name => 'Name A–Z',
      };
}

/// Main Quran tab – browse by surah, juz or revelation order, jump straight
/// to an ayah ("2:255"), and search the text, modelled on quran.com.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  _QuranTab _tab = _QuranTab.surah;
  _SurahFilter _filter = _SurahFilter.all;
  _SurahSort _sort = _SurahSort.mushaf;
  Set<int> _offlineSurahs = {};

  // Verse search
  Timer? _debounce;
  int _searchGeneration = 0;
  List<LocalSearchHit> _localHits = const [];
  List<QuranSearchHit> _onlineHits = const [];
  bool _searchingOnline = false;
  bool _onlineFailed = false;
  int _onlinePage = 1;
  int _onlineTotalPages = 1;
  int _onlineTotal = 0;

  QuranRepository get _repo => context.read<QuranRepository>();

  @override
  void initState() {
    super.initState();
    _refreshOffline();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOffline() async {
    final script = StorageService().getSettings().quranSelectedScript;
    final ids = await _repo.downloadedSurahs(script);
    if (mounted) setState(() => _offlineSurahs = ids);
  }

  // ─────────────────── Search ───────────────────

  void _onQueryChanged(String value) {
    setState(() => _searchQuery = value);
    _debounce?.cancel();
    final q = value.trim();
    final generation = ++_searchGeneration;
    if (q.length < 2 || QuranMeta.parseReference(q) != null || QuranMeta.parseJuz(q) != null) {
      setState(() {
        _localHits = const [];
        _onlineHits = const [];
        _searchingOnline = false;
        _onlineFailed = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runVerseSearch(q, generation));
  }

  Future<void> _runVerseSearch(String q, int generation) async {
    final settings = StorageService().getSettings();
    final local = await _repo.searchLocal(
      q,
      translationId: QuranTranslations.resolve(settings.quranSelectedTranslation).id,
      script: settings.quranSelectedScript,
    );
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _localHits = local;
      _onlineHits = const [];
      _onlinePage = 1;
      _searchingOnline = q.length >= 3;
      _onlineFailed = false;
    });
    if (q.length >= 3) await _loadOnline(q, generation, page: 1);
  }

  Future<void> _loadOnline(String q, int generation, {required int page}) async {
    setState(() => _searchingOnline = true);
    try {
      final result = await _repo.searchOnline(q, page: page);
      if (!mounted || generation != _searchGeneration) return;
      final localKeys = _localHits.map((h) => h.verseKey).toSet();
      setState(() {
        _onlineHits = [
          ..._onlineHits,
          ...result.results.where((h) => !localKeys.contains(h.verseKey)),
        ];
        _onlinePage = page;
        _onlineTotalPages = result.totalPages;
        _onlineTotal = result.totalResults;
        _searchingOnline = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchingOnline = false;
        _onlineFailed = true;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
    FocusScope.of(context).unfocus();
  }

  /// Surahs matching by number, name or meaning. Names are compared with
  /// punctuation and the "Al-" prefix folded away, so "baqara",
  /// "al baqarah" and "Al-Baqarah" all match.
  List<Surah> _matchSurahs(List<Surah> surahs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    final number = int.tryParse(q);
    if (number != null) return surahs.where((s) => s.id == number).toList();
    final folded = _fold(q);
    return surahs.where((s) {
      return _fold(s.nameTransliteration).contains(folded) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(query.trim());
    }).toList();
  }

  static String _fold(String s) {
    var out = s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (out.startsWith('al') && out.length > 4) out = out.substring(2);
    if (out.startsWith('an') && out.length > 5) out = out.substring(2);
    if (out.startsWith('at') && out.length > 5) out = out.substring(2);
    return out.replaceAll('aa', 'a').replaceAll('ee', 'i').replaceAll('oo', 'u').replaceAll(RegExp(r'h$'), '');
  }

  // ─────────────────── Build ───────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        if (state is QuranLoading || state is QuranInitial) {
          return const _QuranLoadingView();
        }

        if (state is QuranError) {
          return _QuranErrorView(
            message: state.message,
            onRetry: () => context.read<QuranBloc>().add(LoadSurahs()),
          );
        }

        if (state is QuranLoaded) {
          return _buildContent(context, state);
        }

        return const _QuranLoadingView();
      },
    );
  }

  Widget _buildContent(BuildContext context, QuranLoaded state) {
    final size = MediaQuery.sizeOf(context);
    // Dynamically calculate horizontal padding (shrinks on small phones, max 24 on large)
    final double hPad = (size.width * 0.05).clamp(16.0, 24.0);
    final bottomPad = MediaQuery.of(context).padding.bottom + 100;
    final searching = _searchQuery.trim().isNotEmpty;

    final List<Widget> slivers;
    if (searching) {
      slivers = _buildSearchResults(state, hPad);
    } else {
      slivers = [
        if (state.lastRead != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ContinueReadingCard(
                surahName: state.lastRead!.surahName ?? 'Surah ${state.lastRead!.surahId}',
                surahId: state.lastRead!.surahId,
                verseNumber: state.lastRead!.verseNumber,
                horizontalPadding: hPad,
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
                  _openSurah(context, state.lastRead!.surahId, verse: state.lastRead!.verseNumber);
                },
              ),
            ),
          ),
        SliverToBoxAdapter(child: _buildTabBar(hPad)),
        ..._buildTab(state, hPad),
      ];
    }

    // 1. Wrap the entire view in a GestureDetector to catch taps outside the search bar
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, (size.height * 0.03).clamp(16.0, 24.0), hPad, 0),
              child: const PageHeader(
                overline: 'THE NOBLE',
                title: 'Quran',
                overlineColor: AppColors.spiritualGold,
              ),
            ),

            SizedBox(height: (size.height * 0.02).clamp(16.0, 24.0)),

            _buildSearchBar(hPad),

            const SizedBox(height: 12),

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                // 2. Automatically dismiss keyboard when the user scrolls the list!
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  ...slivers,
                  SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      // Flat translucent fill rather than a BackdropFilter. What sits
      // behind this is the celestial gradient — a smooth, low-frequency
      // wash — and blurring something already smooth is close to a
      // visual no-op, while a BackdropFilter costs a full offscreen
      // gaussian pass on every frame the page paints, i.e. every frame
      // of a scroll. The fill below reproduces the look at no cost.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white.withValues(alpha: 0.04),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            style: AppTextStyles.body(color: Colors.white),
            // Optional: This makes the "Done/Search" button on the keyboard dismiss it too
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
              final ref = QuranMeta.parseReference(value);
              if (ref != null) _openSurah(context, ref.surah, verse: ref.verse);
            },
            decoration: InputDecoration(
              hintText: 'Surah, 2:255, juz 30, or any word',
              hintStyle: AppTextStyles.body(
                color: Colors.white.withValues(alpha: 0.4),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.spiritualGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Row(
          children: [
            for (final tab in _QuranTab.values)
              Expanded(
                child: Pressable(
                  pressedScale: 0.96,
                  haptic: PressableHaptic.none,
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_tab == tab) return;
                    HapticService().selection();
                    setState(() => _tab = tab);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tab == tab ? AppColors.spiritualGold.withValues(alpha: 0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tab.label,
                      style: AppTextStyles.small(
                        color: _tab == tab ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.55),
                        weight: _tab == tab ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTab(QuranLoaded state, double hPad) {
    switch (_tab) {
      case _QuranTab.surah:
      case _QuranTab.revelation:
        return _buildSurahTab(state, hPad, byRevelation: _tab == _QuranTab.revelation);
      case _QuranTab.juz:
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _JuzCard(
                juz: i + 1,
                surahs: state.surahs,
                horizontalPadding: hPad,
                onOpen: (surah, verse) => _openSurah(context, surah, verse: verse),
              ),
              childCount: 30,
            ),
          ),
        ];
      case _QuranTab.saved:
        return _buildSavedTab(state, hPad);
    }
  }

  List<Widget> _buildSurahTab(QuranLoaded state, double hPad, {required bool byRevelation}) {
    var surahs = state.surahs.where((s) {
      final makki = s.revelationPlace.toLowerCase() == 'makkah';
      return switch (_filter) {
        _SurahFilter.all => true,
        _SurahFilter.makki => makki,
        _SurahFilter.madani => !makki,
        _SurahFilter.offline => _offlineSurahs.contains(s.id),
      };
    }).toList();

    if (byRevelation) {
      surahs.sort((a, b) => a.revelationOrder.compareTo(b.revelationOrder));
    } else {
      switch (_sort) {
        case _SurahSort.mushaf:
          break;
        case _SurahSort.longest:
          surahs.sort((a, b) => b.versesCount.compareTo(a.versesCount));
        case _SurahSort.shortest:
          surahs.sort((a, b) => a.versesCount.compareTo(b.versesCount));
        case _SurahSort.name:
          surahs.sort((a, b) => _fold(a.nameTransliteration).compareTo(_fold(b.nameTransliteration)));
      }
    }

    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            children: [
              for (final f in _SurahFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: f == _SurahFilter.offline ? 'Offline · ${_offlineSurahs.length}' : f.label,
                    icon: f == _SurahFilter.offline ? Icons.offline_pin_rounded : null,
                    selected: _filter == f,
                    onTap: () {
                      HapticService().selection();
                      setState(() => _filter = f);
                    },
                  ),
                ),
              if (!byRevelation) _buildSortButton(),
            ],
          ),
        ),
      ),
      if (byRevelation)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad + 4, 12, hPad, 0),
            child: Text(
              'Surahs in the order they were revealed to the Prophet ﷺ',
              style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      if (surahs.isEmpty)
        SliverToBoxAdapter(
          child: _EmptyHint(
            icon: _filter == _SurahFilter.offline ? Icons.cloud_download_outlined : Icons.search_off_rounded,
            text: _filter == _SurahFilter.offline
                ? 'No surahs saved yet.\nEach surah is saved the first time you open it.'
                : 'No surahs found',
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final surah = surahs[index];
              return _SurahListTile(
                surah: surah,
                horizontalPadding: hPad,
                badge: byRevelation ? surah.revelationOrder : surah.id,
                caption: byRevelation ? 'Surah ${surah.id}' : null,
                isOffline: _offlineSurahs.contains(surah.id),
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
                  _openSurah(context, surah.id);
                },
              );
            },
            childCount: surahs.length,
          ),
        ),
    ];
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_SurahSort>(
      initialValue: _sort,
      color: const Color(0xFF1C1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (s) {
        HapticService().selection();
        setState(() => _sort = s);
      },
      itemBuilder: (_) => [
        for (final s in _SurahSort.values)
          PopupMenuItem(
            value: s,
            child: Text(
              s.label,
              style: AppTextStyles.small(
                color: s == _sort ? AppColors.spiritualGold : Colors.white,
                weight: s == _sort ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: _FilterPill(
        label: _sort.label,
        icon: Icons.swap_vert_rounded,
        selected: _sort != _SurahSort.mushaf,
      ),
    );
  }

  List<Widget> _buildSavedTab(QuranLoaded state, double hPad) {
    if (state.bookmarks.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: _EmptyHint(
            icon: Icons.bookmark_border_rounded,
            text: 'No bookmarks yet.\nLong-press any ayah while reading to save it here.',
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final bm = state.bookmarks[i];
            return _BookmarkTile(
              key: ValueKey(bm.id),
              bookmark: bm,
              surah: _repo.surahById(bm.surahId),
              horizontalPadding: hPad,
              onTap: () => _openSurah(context, bm.surahId, verse: bm.verseNumber),
              onDelete: () {
                HapticService().medium();
                context.read<QuranBloc>().add(DeleteBookmark(bm.id));
              },
            );
          },
          childCount: state.bookmarks.length,
        ),
      ),
    ];
  }

  List<Widget> _buildSearchResults(QuranLoaded state, double hPad) {
    final q = _searchQuery.trim();
    final ref = QuranMeta.parseReference(q);
    final juz = QuranMeta.parseJuz(q);
    final surahMatches = ref == null && juz == null ? _matchSurahs(state.surahs, q) : const <Surah>[];
    final verseHits = _localHits.length + _onlineHits.length;

    final children = <Widget>[];

    if (ref != null) {
      final surah = _repo.surahById(ref.surah)!;
      children.add(_JumpCard(
        horizontalPadding: hPad,
        icon: Icons.menu_book_rounded,
        title: '${surah.nameTransliteration} · Ayah ${ref.verse}',
        subtitle: 'Go to ${ref.key} · ${surah.nameTranslation}',
        onTap: () => _openSurah(context, ref.surah, verse: ref.verse),
      ));
    }
    if (juz != null) {
      final (s, v) = QuranMeta.juzStarts[juz - 1];
      final surah = _repo.surahById(s)!;
      children.add(_JumpCard(
        horizontalPadding: hPad,
        icon: Icons.auto_stories_rounded,
        title: 'Juz $juz',
        subtitle: 'Starts at ${surah.nameTransliteration} $s:$v',
        onTap: () => _openSurah(context, s, verse: v),
      ));
    }

    if (surahMatches.isNotEmpty) {
      children.add(_SectionLabel(text: 'SURAHS', horizontalPadding: hPad));
      for (final surah in surahMatches.take(ref == null ? 8 : 3)) {
        children.add(_SurahListTile(
          surah: surah,
          horizontalPadding: hPad,
          badge: surah.id,
          isOffline: _offlineSurahs.contains(surah.id),
          onTap: () {
            FocusScope.of(context).unfocus();
            _openSurah(context, surah.id);
          },
        ));
      }
    }

    if (ref == null && juz == null && q.length >= 2) {
      children.add(_SectionLabel(
        text: _onlineTotal > 0 ? 'AYAHS · ${_onlineTotal + _localHits.length}' : 'AYAHS',
        horizontalPadding: hPad,
      ));
      for (final hit in _localHits) {
        final surah = _repo.surahById(hit.surah);
        children.add(_VerseResultTile(
          horizontalPadding: hPad,
          reference: '${surah?.nameTransliteration ?? 'Surah'} ${hit.verseKey}',
          text: hit.snippet,
          arabic: hit.source == SearchMatchSource.arabic,
          query: hit.source == SearchMatchSource.translation ? q : null,
          tag: hit.source == SearchMatchSource.transliteration ? 'Transliteration' : null,
          onTap: () => _openSurah(context, hit.surah, verse: hit.verse),
        ));
      }
      for (final hit in _onlineHits) {
        final surah = _repo.surahById(hit.surah);
        children.add(_VerseResultTile(
          horizontalPadding: hPad,
          reference: '${surah?.nameTransliteration ?? 'Surah'} ${hit.verseKey}',
          text: hit.translation ?? hit.arabic,
          arabicPreview: hit.translation != null ? hit.arabic : null,
          arabic: hit.translation == null,
          query: q,
          onTap: () => _openSurah(context, hit.surah, verse: hit.verse),
        ));
      }
      if (_searchingOnline) {
        children.add(const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.spiritualGold),
            ),
          ),
        ));
      } else if (_onlineFailed) {
        children.add(_EmptyHint(
          icon: Icons.cloud_off_rounded,
          text: verseHits == 0
              ? 'No matches saved on this device.\nConnect to the internet to search the full Quran.'
              : 'Showing matches saved on this device.\nConnect to search the full Quran.',
        ));
      } else if (_onlinePage < _onlineTotalPages && _onlineHits.isNotEmpty) {
        children.add(Center(
          child: TextButton(
            onPressed: () => _loadOnline(q, _searchGeneration, page: _onlinePage + 1),
            style: TextButton.styleFrom(foregroundColor: AppColors.spiritualGold),
            child: const Text('Load more'),
          ),
        ));
      } else if (verseHits == 0 && surahMatches.isEmpty && q.length >= 3) {
        children.add(const _EmptyHint(icon: Icons.search_off_rounded, text: 'No results found'));
      }
    }

    return [SliverList(delegate: SliverChildListDelegate(children))];
  }

  void _openSurah(BuildContext context, int surahId, {int? verse}) {
    HapticService().light();
    final surahName = _repo.surahById(surahId)?.nameTransliteration;

    final prayerState = context.read<PrayerBloc>().state;
    final prayerPeriod = prayerState is PrayerLoaded
        ? prayerState.prayerPeriod
        : PrayerPeriod.isha;

    Navigator.of(context).push(
      AppRoute(
        builder: (context) => SurahReadingScreen(
              surahId: surahId,
              surahName: surahName,
              prayerPeriod: prayerPeriod,
              initialVerse: verse,
            ),
      ),
    ).then((_) => _refreshOffline());
  }
}

// ─────────────────── Small building blocks ───────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterPill({required this.label, required this.selected, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.65);
    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.spiritualGold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.spiritualGold.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 6)],
          Text(label, style: AppTextStyles.small(color: color, weight: selected ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Pressable(onTap: onTap, pressedScale: 0.95, haptic: PressableHaptic.selection, child: pill);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double horizontalPadding;

  const _SectionLabel({required this.text, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding + 4, 16, horizontalPadding, 10),
      child: Text(
        text,
        style: AppTextStyles.tiny(color: AppColors.spiritualGold.withValues(alpha: 0.8))
            .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

/// Prominent "go to" result for a verse reference or juz typed in search.
class _JumpCard extends StatelessWidget {
  final double horizontalPadding;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _JumpCard({
    required this.horizontalPadding,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.975,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.spiritualGold.withValues(alpha: 0.14),
              AppColors.spiritualGold.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.spiritualGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.spiritualGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(color: AppColors.spiritualGold, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _VerseResultTile extends StatelessWidget {
  final double horizontalPadding;
  final String reference;
  final String text;
  final String? arabicPreview;
  final bool arabic;
  final String? query;
  final String? tag;
  final VoidCallback onTap;

  const _VerseResultTile({
    required this.horizontalPadding,
    required this.reference,
    required this.text,
    required this.onTap,
    this.arabicPreview,
    this.arabic = false,
    this.query,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final base = arabic
        ? AppTextStyles.arabic(color: Colors.white.withValues(alpha: 0.85), size: 20).copyWith(height: 1.8)
        : AppTextStyles.small(color: Colors.white.withValues(alpha: 0.78)).copyWith(height: 1.5);
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reference,
                    style: AppTextStyles.small(color: AppColors.spiritualGold, weight: FontWeight.w600),
                  ),
                ),
                if (tag != null)
                  Text(tag!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.35))),
              ],
            ),
            if (arabicPreview != null) ...[
              const SizedBox(height: 8),
              Text(
                arabicPreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.arabic(color: Colors.white.withValues(alpha: 0.6), size: 17),
              ),
            ],
            const SizedBox(height: 6),
            Text.rich(
              _highlight(text, query, base),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textDirection: arabic ? TextDirection.rtl : null,
            ),
          ],
        ),
      ),
    );
  }

  static TextSpan _highlight(String text, String? query, TextStyle base) {
    final words = (query ?? '').toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.isEmpty) return TextSpan(text: text, style: base);
    final pattern = RegExp(words.map(RegExp.escape).join('|'), caseSensitive: false);
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(color: AppColors.spiritualGold, fontWeight: FontWeight.w600),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}

// ─────────────────── Juz Card ───────────────────

class _JuzCard extends StatefulWidget {
  final int juz;
  final List<Surah> surahs;
  final double horizontalPadding;
  final void Function(int surah, int verse) onOpen;

  const _JuzCard({
    required this.juz,
    required this.surahs,
    required this.horizontalPadding,
    required this.onOpen,
  });

  @override
  State<_JuzCard> createState() => _JuzCardState();
}

class _JuzCardState extends State<_JuzCard> {
  bool _expanded = false;

  String _name(int id) => widget.surahs.length >= id ? widget.surahs[id - 1].nameTransliteration : 'Surah $id';

  @override
  Widget build(BuildContext context) {
    final segments = QuranMeta.juzSegments(widget.juz);
    final first = segments.first;
    final last = segments.last;
    final isSmallPhone = MediaQuery.sizeOf(context).width < 360;

    return Container(
      margin: EdgeInsets.fromLTRB(widget.horizontalPadding, 0, widget.horizontalPadding, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? AppColors.spiritualGold.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Pressable(
            onTap: () => widget.onOpen(first.surah, first.fromVerse),
            onLongPress: () => setState(() => _expanded = !_expanded),
            pressedScale: 0.98,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 14 : 16, vertical: isSmallPhone ? 12 : 14),
              child: Row(
                children: [
                  Container(
                    width: isSmallPhone ? 32 : 36,
                    height: isSmallPhone ? 32 : 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.spiritualGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.2), width: 0.5),
                    ),
                    child: Text(
                      '${widget.juz}',
                      style: AppTextStyles.small(color: AppColors.spiritualGold, weight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: isSmallPhone ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Juz ${widget.juz}', style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          first.surah == last.surah
                              ? '${_name(first.surah)} ${first.surah}:${first.fromVerse}–${last.toVerse}'
                              : '${_name(first.surah)} ${first.surah}:${first.fromVerse} – ${_name(last.surah)} ${last.surah}:${last.toVerse}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    pressedScale: 0.97,
                    haptic: PressableHaptic.none,
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService().selection();
                      setState(() => _expanded = !_expanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more_rounded, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      children: [
                        for (final seg in segments)
                          Pressable(
                            pressedScale: 0.98,
                            onTap: () => widget.onOpen(seg.surah, seg.fromVerse),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${seg.surah}',
                                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _name(seg.surah),
                                      style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                  ),
                                  Text(
                                    seg.fromVerse == 1 && seg.toVerse == QuranMeta.verseCounts[seg.surah - 1]
                                        ? 'Complete'
                                        : 'Ayah ${seg.fromVerse}–${seg.toVerse}',
                                    style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Bookmark Tile ───────────────────

class _BookmarkTile extends StatelessWidget {
  final QuranBookmark bookmark;
  final Surah? surah;
  final double horizontalPadding;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    super.key,
    required this.bookmark,
    required this.surah,
    required this.horizontalPadding,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${bookmark.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.statusMissed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.statusMissed),
      ),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.975,
        child: Container(
          margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: AppColors.spiritualGold, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah?.nameTransliteration ?? bookmark.surahName ?? 'Surah ${bookmark.surahId}',
                      style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ayah ${bookmark.surahId}:${bookmark.verseNumber}${surah != null ? ' · ${surah!.nameTranslation}' : ''}',
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              if (surah != null)
                Text(surah!.nameArabic, style: AppTextStyles.arabic(color: AppColors.spiritualGold, size: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Continue Reading Card ───────────────────

class _ContinueReadingCard extends StatelessWidget {
  final String surahName;
  final int surahId;
  final int verseNumber;
  final double horizontalPadding;
  final VoidCallback onTap;

  const _ContinueReadingCard({
    required this.surahName,
    required this.surahId,
    required this.verseNumber,
    required this.horizontalPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isSmallPhone = size.width < 360;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
      child: Pressable(
        pressedScale: 0.98,
        onTap: onTap,
        // See the search bar above: blurring the smooth celestial gradient
        // behind this card buys nothing visually and costs an offscreen
        // gaussian pass per frame. The gradient fill below carries the look.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
              padding: EdgeInsets.all(isSmallPhone ? 14.0 : 16.0), // Responsive padding
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
                border: Border.all(
                  color: AppColors.spiritualGold.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallPhone ? 8.0 : 10.0),
                    decoration: BoxDecoration(
                      color: AppColors.spiritualGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.spiritualGold,
                      size: isSmallPhone ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Reading',
                          style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6))
                              .copyWith(letterSpacing: 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          surahName,
                          style: AppTextStyles.body(color: AppColors.spiritualGold)
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Verse $verseNumber',
                          style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Surah List Tile ───────────────────

class _SurahListTile extends StatelessWidget {
  final Surah surah;
  final double horizontalPadding;
  final VoidCallback onTap;

  /// Number in the circle: the surah number, or its revelation order.
  final int badge;

  /// Optional extra caption after the ayah count (e.g. "Surah 96").
  final String? caption;
  final bool isOffline;

  const _SurahListTile({
    required this.surah,
    required this.horizontalPadding,
    required this.onTap,
    required this.badge,
    this.caption,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isSmallPhone = size.width < 360;
    final isMakki = surah.revelationPlace.toLowerCase() == 'makkah';

    return Pressable(
      onTap: onTap,
      pressedScale: 0.975,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
        padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 14 : 16,
            vertical: isSmallPhone ? 12 : 14
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Responsive Surah Number Badge
            Container(
              width: isSmallPhone ? 32 : 36,
              height: isSmallPhone ? 32 : 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$badge',
                style: AppTextStyles.small(
                  color: Colors.white.withValues(alpha: 0.8),
                  weight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: isSmallPhone ? 10 : 14),

            // Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTransliteration,
                    style: AppTextStyles.body(
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          surah.nameTranslation,
                          style: AppTextStyles.tiny(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CircleAvatar(radius: 2, backgroundColor: Colors.white.withValues(alpha: 0.3)),
                      ),
                      Text(
                        caption != null ? '${surah.versesCount} Ayahs · $caption' : '${surah.versesCount} Ayahs',
                        style: AppTextStyles.tiny(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        // Don't shrink the verses count label
                        maxLines: 1,
                      ),
                      if (isOffline) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.offline_pin_rounded, size: 12, color: AppColors.spiritualGold.withValues(alpha: 0.6)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arabic Name + Revelation Icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  surah.nameArabic,
                  style: AppTextStyles.arabic(
                    color: AppColors.spiritualGold,
                    size: isSmallPhone ? 16 : 18, // Scales down gracefully
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: 0.45,
                      child: Text(
                        isMakki ? '🕋' : '🕌',
                        style: TextStyle(fontSize: isSmallPhone ? 10 : 11, height: 1.0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMakki ? 'Makki' : 'Madani',
                      style: AppTextStyles.tiny(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Loading / Error Views ───────────────────

class _QuranLoadingView extends StatelessWidget {
  const _QuranLoadingView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PremiumFlowingLoader(
              size: 50.0,
              color: AppColors.spiritualGold,
            ),
            const SizedBox(height: 24),
            Text(
              'Opening Quran...',
              style: AppTextStyles.body(
                color: Colors.white.withValues(alpha: 0.7),
                weight: FontWeight.w500,
              ).copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuranErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load Quran data',
                style: AppTextStyles.body(
                  color: Colors.white.withValues(alpha: 0.8),
                  weight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection\nand try again.',
                style: AppTextStyles.small(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}