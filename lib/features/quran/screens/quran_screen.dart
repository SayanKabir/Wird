import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wird2/widgets/common/premium_flowing_loader.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../features/home/bloc/prayer_bloc.dart';
import '../../../models/surah.dart';
import '../bloc/quran_bloc.dart';
import 'surah_reading_screen.dart';

/// Main Quran tab – shows list of 114 surahs with search and last-read position
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          return _buildSurahList(context, state);
        }

        return const _QuranLoadingView();
      },
    );
  }

  Widget _buildSurahList(BuildContext context, QuranLoaded state) {
    final size = MediaQuery.sizeOf(context);
    // Dynamically calculate horizontal padding (shrinks on small phones, max 24 on large)
    final double hPad = (size.width * 0.05).clamp(16.0, 24.0);

    final filteredSurahs = _searchQuery.isEmpty
        ? state.surahs
        : state.surahs.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.id.toString() == q;
    }).toList();

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE NOBLE',
                    style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                        .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Quran', style: AppTextStyles.h1()),
                ],
              ),
            ),

            SizedBox(height: (size.height * 0.02).clamp(16.0, 24.0)),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTextStyles.body(color: Colors.white),
                    // Optional: This makes the "Done/Search" button on the keyboard dismiss it too
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Search surahs...',
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
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
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
            ),

            const SizedBox(height: 16),

            // Continue Reading Card
            if (state.lastRead != null && _searchQuery.isEmpty) ...[
              _ContinueReadingCard(
                  surahName: state.lastRead!.surahName ?? 'Surah ${state.lastRead!.surahId}',
                  surahId: state.lastRead!.surahId,
                  verseNumber: state.lastRead!.verseNumber,
                  horizontalPadding: hPad,
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
                    _openSurah(context, state.lastRead!.surahId);
                  }
              ),
              const SizedBox(height: 8),
            ],

            // Surah List
            Expanded(
              child: filteredSurahs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'No surahs found',
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                // 2. Automatically dismiss keyboard when the user scrolls the list!
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: MediaQuery.of(context).padding.bottom + 100,
                ),
                itemCount: filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = filteredSurahs[index];
                  return _SurahListTile(
                      surah: surah,
                      horizontalPadding: hPad,
                      onTap: () {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
                        _openSurah(context, surah.id);
                      }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSurah(BuildContext context, int surahId) {
    HapticFeedback.lightImpact();
    final bloc = context.read<QuranBloc>();
    final state = bloc.state;
    String? surahName;
    if (state is QuranLoaded) {
      final s = state.surahs.where((s) => s.id == surahId).firstOrNull;
      surahName = s?.nameTransliteration;
    }

    final prayerState = context.read<PrayerBloc>().state;
    final prayerPeriod = prayerState is PrayerLoaded
        ? prayerState.prayerPeriod
        : PrayerPeriod.isha;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SurahReadingScreen(
              surahId: surahId,
              surahName: surahName,
              prayerPeriod: prayerPeriod,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
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
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
      ),
    );
  }
}

// ─────────────────── Surah List Tile ───────────────────

class _SurahListTile extends StatelessWidget {
  final Surah surah;
  final double horizontalPadding;
  final VoidCallback onTap;

  const _SurahListTile({
    required this.surah,
    required this.horizontalPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isSmallPhone = size.width < 360;
    final isMakki = surah.revelationPlace.toLowerCase() == 'makkah';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
                '${surah.id}',
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
                        '${surah.versesCount} Verses',
                        style: AppTextStyles.tiny(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        // Don't shrink the verses count label
                        maxLines: 1,
                      ),
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