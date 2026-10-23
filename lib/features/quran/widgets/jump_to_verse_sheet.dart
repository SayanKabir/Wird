import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/quran/quran_meta.dart';
import '../../../core/quran/surah_search.dart';
import '../../../core/repositories/quran_repository.dart';
import '../../../core/services/haptic_service.dart';
import '../../../models/surah.dart';
import '../../../models/verse.dart';

/// Where the Go to sheet sends the reader.
sealed class JumpTarget {
  const JumpTarget();
}

/// An ayah in the open surah.
class JumpToAyah extends JumpTarget {
  final int verse;
  const JumpToAyah(this.verse);
}

/// An ayah in a different surah.
class JumpToSurah extends JumpTarget {
  final int surah;
  final int verse;
  const JumpToSurah(this.surah, this.verse);
}

/// The reader's Go to sheet: a slider and shortcuts at rest, and a single box
/// that understands "45", "2:255", "juz 5", surah names and words.
Future<JumpTarget?> showJumpToVerseSheet(
  BuildContext context, {
  required Surah surah,
  required List<Surah> surahs,
  required List<Verse> verses,
  required int currentVerse,
  int? lastReadVerse,
  List<int> bookmarkedVerses = const [],
}) {
  HapticService().light();
  return showModalBottomSheet<JumpTarget>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _JumpSheet(
      surah: surah,
      surahs: surahs,
      verses: verses,
      currentVerse: currentVerse,
      lastReadVerse: lastReadVerse,
      bookmarkedVerses: bookmarkedVerses,
    ),
  );
}

class _JumpSheet extends StatefulWidget {
  final Surah surah;
  final List<Surah> surahs;
  final List<Verse> verses;
  final int currentVerse;
  final int? lastReadVerse;
  final List<int> bookmarkedVerses;

  const _JumpSheet({
    required this.surah,
    required this.surahs,
    required this.verses,
    required this.currentVerse,
    required this.lastReadVerse,
    required this.bookmarkedVerses,
  });

  @override
  State<_JumpSheet> createState() => _JumpSheetState();
}

class _Result {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? query; // highlighted in the subtitle
  final JumpTarget target;

  const _Result({required this.icon, required this.title, required this.target, this.subtitle, this.query});
}

class _JumpSheetState extends State<_JumpSheet> {
  final TextEditingController _controller = TextEditingController();
  late double _slider = widget.currentVerse.toDouble();

  int get _count => widget.verses.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(JumpTarget target) {
    HapticService().selection();
    Navigator.pop(context, target);
  }

  List<_Result> _results(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return const [];
    final results = <_Result>[];
    final surah = widget.surah;

    // "45" → ayah of this surah
    final number = int.tryParse(q);
    if (number != null && number >= 1 && number <= _count) {
      results.add(_Result(
        icon: Icons.arrow_downward_rounded,
        title: 'Ayah $number',
        subtitle: _preview(widget.verses[number - 1]),
        target: JumpToAyah(number),
      ));
    }

    // "2:255"
    final ref = QuranMeta.parseReference(q);
    if (ref != null) {
      final s = widget.surahs[ref.surah - 1];
      results.add(_Result(
        icon: Icons.menu_book_rounded,
        title: '${s.nameTransliteration} · Ayah ${ref.verse}',
        subtitle: ref.surah == surah.id ? 'In this surah' : s.nameTranslation,
        target: ref.surah == surah.id ? JumpToAyah(ref.verse) : JumpToSurah(ref.surah, ref.verse),
      ));
    }

    // "juz 5"
    final juz = QuranMeta.parseJuz(q);
    if (juz != null) {
      final (s, v) = QuranMeta.juzStarts[juz - 1];
      results.add(_Result(
        icon: Icons.auto_stories_rounded,
        title: 'Juz $juz',
        subtitle: 'Starts at ${widget.surahs[s - 1].nameTransliteration} $s:$v',
        target: s == surah.id ? JumpToAyah(v) : JumpToSurah(s, v),
      ));
    }

    if (number != null || ref != null || juz != null || q.length < 2) return results;

    // Surah names
    for (final s in SurahSearch.match(widget.surahs, q).where((s) => s.id != surah.id).take(3)) {
      results.add(_Result(
        icon: Icons.swap_horiz_rounded,
        title: 'Open ${s.nameTransliteration}',
        subtitle: '${s.nameTranslation} · ${s.versesCount} ayahs',
        target: JumpToSurah(s.id, 1),
      ));
    }

    // Words inside this surah
    final words = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(q);
    final arabicNeedle = isArabic ? QuranRepository.normalizeArabic(q) : '';
    final latinNeedle = QuranRepository.normalizeLatin(q);
    var found = 0;
    for (final v in widget.verses) {
      if (found >= 40) break;
      String? snippet;
      if (isArabic) {
        if (QuranRepository.normalizeArabic(v.textUthmani).contains(arabicNeedle)) snippet = v.textUthmani;
      } else {
        final translation = v.translationText ?? '';
        if (translation.isNotEmpty && words.every(translation.toLowerCase().contains)) {
          snippet = translation;
        } else if (latinNeedle.length >= 3 &&
            QuranRepository.normalizeLatin(v.transliterationText ?? '').contains(latinNeedle)) {
          snippet = v.transliterationText;
        }
      }
      if (snippet == null) continue;
      found++;
      results.add(_Result(
        icon: Icons.format_quote_rounded,
        title: 'Ayah ${v.verseNumber}',
        subtitle: snippet,
        query: isArabic ? null : q,
        target: JumpToAyah(v.verseNumber),
      ));
    }
    return results;
  }

  String? _preview(Verse v) {
    final t = v.translationText ?? v.transliterationText;
    if (t == null || t.isEmpty) return null;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = _results(query);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.75),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + (media.viewInsets.bottom > 0 ? 0 : media.padding.bottom)),
            decoration: BoxDecoration(
              color: const Color(0xFF151A2C).withValues(alpha: 0.92),
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
                const SizedBox(height: 16),
                Text('GO TO', style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 3, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) {
                    if (results.isNotEmpty) _go(results.first.target);
                  },
                  style: AppTextStyles.body(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ayah number, 2:255, juz, or a word',
                    hintStyle: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.35)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                            onPressed: () => setState(_controller.clear),
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.spiritualGold.withValues(alpha: 0.6), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (query.trim().isEmpty)
                  _buildBrowse()
                else
                  Flexible(child: _buildResults(results)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowse() {
    final shortcuts = <(String, int)>[
      if (widget.lastReadVerse != null && widget.lastReadVerse! > 1) ('Last read · ${widget.lastReadVerse}', widget.lastReadVerse!),
      for (final b in widget.bookmarkedVerses.take(6)) ('Bookmark · $b', b),
      if (_count > 1) ('Start', 1),
      if (_count > 1) ('End · $_count', _count),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_count >= 12) ...[
          Row(
            children: [
              Text(
                'Ayah ${_slider.round()}',
                style: AppTextStyles.h3(color: Colors.white),
              ),
              Text(
                '  of $_count',
                style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.45)),
              ),
              const Spacer(),
              Text(
                'Juz ${QuranMeta.juzOf(widget.surah.id, _slider.round())}',
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.spiritualGold.withValues(alpha: 0.6),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppColors.spiritualGold,
              overlayColor: AppColors.spiritualGold.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _slider.clamp(1, _count.toDouble()),
              min: 1,
              max: _count.toDouble(),
              onChanged: (v) {
                if (v.round() != _slider.round()) HapticService().selection();
                setState(() => _slider = v);
              },
              onChangeEnd: (v) => _go(JumpToAyah(v.round())),
            ),
          ),
        ] else
          // Short surahs: every ayah as a chip reads better than a slider.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 1; i <= _count; i++) _Chip(label: '$i', onTap: () => _go(JumpToAyah(i)), selected: i == widget.currentVerse),
            ],
          ),
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, verse) in shortcuts) _Chip(label: label, onTap: () => _go(JumpToAyah(verse))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResults(List<_Result> results) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No matches in ${widget.surah.nameTransliteration}.\nThe Quran tab searches the whole Quran.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[i];
        return InkWell(
          onTap: () => _go(r.target),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(r.icon, size: 18, color: AppColors.spiritualGold.withValues(alpha: 0.85)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600)),
                      if (r.subtitle != null)
                        Text.rich(
                          _highlight(r.subtitle!, r.query),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bolds query words in a snippet, starting the snippet near the first
  /// match so it's visible within two lines.
  static TextSpan _highlight(String text, String? query) {
    final words = (query ?? '').toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.isEmpty) return TextSpan(text: text);
    final pattern = RegExp(words.map(RegExp.escape).join('|'), caseSensitive: false);
    final first = pattern.firstMatch(text);
    if (first != null && first.start > 60) text = '…${text.substring(first.start - 40)}';
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
    return TextSpan(children: spans);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _Chip({required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.spiritualGold.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.spiritualGold.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.small(
            color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.8),
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
