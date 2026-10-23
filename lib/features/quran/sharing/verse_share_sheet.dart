import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../features/home/bloc/prayer_bloc.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/glass_snackbar.dart';
import 'share_backgrounds.dart';
import 'verse_share.dart';

/// Images stay legible up to this many ayahs; longer selections share as text.
const int kMaxImageVerses = 10;

/// Bottom sheet offering the three ways to share a selection of ayahs.
Future<void> showVerseShareSheet(
  BuildContext context, {
  required VerseShare share,
  required QuranScript script,
  required bool includeTranslation,
  required bool includeTransliteration,
}) {
  HapticService().light();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder:
        (_) => _VerseShareSheet(
          share: share,
          script: script,
          includeTranslation: includeTranslation,
          includeTransliteration: includeTransliteration,
        ),
  );
}

class _VerseShareSheet extends StatefulWidget {
  final VerseShare share;
  final QuranScript script;
  final bool includeTranslation;
  final bool includeTransliteration;

  const _VerseShareSheet({
    required this.share,
    required this.script,
    required this.includeTranslation,
    required this.includeTransliteration,
  });

  @override
  State<_VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<_VerseShareSheet> {
  late bool _translation = widget.includeTranslation && _hasTranslation;
  late bool _transliteration = widget.includeTransliteration;

  bool get _hasTranslation =>
      widget.share.verses.any((v) => (v.translationText ?? '').isNotEmpty);
  bool get _imageAllowed => widget.share.verses.length <= kMaxImageVerses;

  Future<void> _shareText() async {
    HapticService().selection();
    final text = widget.share.toText(
      translation: _translation,
      transliteration: _transliteration,
    );
    Navigator.pop(context);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Quran ${widget.share.title}'),
    );
  }

  Future<void> _shareLink() async {
    HapticService().selection();
    Navigator.pop(context);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Quran, ${widget.share.title}\n${widget.share.link}',
        subject: 'Quran ${widget.share.title}',
      ),
    );
  }

  Future<void> _copyText() async {
    HapticService().selection();
    await Clipboard.setData(
      ClipboardData(
        text: widget.share.toText(
          translation: _translation,
          transliteration: _transliteration,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    GlassSnackBar.show(
      context,
      message: 'Copied ${widget.share.title}',
      icon: Icons.check_rounded,
    );
  }

  void _openImage() {
    HapticService().selection();
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => VerseImagePreview(
              share: widget.share,
              script: widget.script,
              translation: _translation,
              transliteration: _transliteration,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < 360;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            small ? 20 : 24,
            12,
            small ? 20 : 24,
            (small ? 24 : 32) + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: small ? 20 : 24),
              Text(
                'SHARE',
                style: AppTextStyles.tiny(
                  color: AppColors.spiritualGold,
                ).copyWith(letterSpacing: 3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.share.title,
                style: AppTextStyles.h3(color: Colors.white),
              ),
              Text(
                widget.share.verses.length == 1
                    ? '1 ayah'
                    : '${widget.share.verses.length} ayahs',
                style: AppTextStyles.tiny(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (_hasTranslation)
                    _IncludeChip(
                      label: 'Translation',
                      selected: _translation,
                      onTap: () => setState(() => _translation = !_translation),
                    ),
                  _IncludeChip(
                    label: 'Transliteration',
                    selected: _transliteration,
                    onTap:
                        () => setState(
                          () => _transliteration = !_transliteration,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ShareOption(
                icon: Icons.image_rounded,
                title: 'Image',
                subtitle:
                    _imageAllowed
                        ? 'A card for chats and stories'
                        : 'Up to $kMaxImageVerses ayahs fit on an image. Share as text instead',
                enabled: _imageAllowed,
                onTap: _openImage,
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.notes_rounded,
                title: 'Text',
                subtitle:
                    'Arabic${_translation ? ' and translation' : ''}, with a link',
                onTap: _shareText,
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.link_rounded,
                title: 'Link',
                subtitle:
                    'Opens ${widget.share.reference} on quran.com, or in Wird',
                onTap: _shareLink,
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.copy_rounded,
                title: 'Copy text',
                subtitle: 'Paste it anywhere',
                onTap: _copyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncludeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IncludeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        HapticService().selection();
        onTap();
      },
      showCheckmark: true,
      checkmarkColor: AppColors.spiritualGold,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: AppColors.spiritualGold.withValues(alpha: 0.18),
      labelStyle: AppTextStyles.small(
        color:
            selected
                ? AppColors.spiritualGold
                : Colors.white.withValues(alpha: 0.7),
        weight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.spiritualGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.spiritualGold, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.tiny(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// IMAGE
// =============================================================================

/// The last sky and weather picked, so a second share starts from them.
PrayerPeriod? _lastPeriod;
ShareWeather _lastWeather = ShareWeather.clear;

/// Full-screen preview of the share card with a background picker; the card
/// is captured to PNG on share.
class VerseImagePreview extends StatefulWidget {
  final VerseShare share;
  final QuranScript script;
  final bool translation;
  final bool transliteration;

  const VerseImagePreview({
    super.key,
    required this.share,
    required this.script,
    required this.translation,
    required this.transliteration,
  });

  @override
  State<VerseImagePreview> createState() => _VerseImagePreviewState();
}

class _VerseImagePreviewState extends State<VerseImagePreview> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  late ShareBackground _background;
  ShareWeather _weather = _lastWeather;

  @override
  void initState() {
    super.initState();
    // Start from the sky the user is under right now.
    final prayerState = context.read<PrayerBloc>().state;
    _background = ShareBackground.forPeriod(
      _lastPeriod ?? (prayerState is PrayerLoaded ? prayerState.prayerPeriod : PrayerPeriod.isha),
    );
  }

  void _pickSky(ShareBackground b) {
    HapticService().selection();
    _lastPeriod = b.period;
    setState(() => _background = b);
  }

  void _pickWeather(ShareWeather w) {
    HapticService().selection();
    _lastWeather = w;
    setState(() => _weather = w);
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticService().medium();
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 3× the 360pt card → a 1080px-wide image, the usual size for chats
      // and stories.
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = await getTemporaryDirectory();
      final ref = widget.share.reference.replaceAll(RegExp(r'[^0-9]+'), '-');
      final file = File('${dir.path}/quran-$ref.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'Quran, ${widget.share.title}\n${widget.share.link}',
        subject: 'Quran ${widget.share.title}',
      ));
    } catch (e) {
      if (mounted) {
        GlassSnackBar.show(context, message: 'Couldn\'t create the image', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Share as image', style: AppTextStyles.h3(color: Colors.white)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FittedBox(
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: VerseShareCard(
                            key: ValueKey('${_background.period.name}-${_weather.name}'),
                            share: widget.share,
                            script: widget.script,
                            translation: widget.translation,
                            transliteration: widget.transliteration,
                            background: _background,
                            weather: _weather,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF12162A),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PickerLabel('TIME OF DAY'),
                  SizedBox(
                    height: 62,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final b in ShareBackground.all)
                          _BackgroundSwatch(
                            background: b,
                            selected: b.period == _background.period,
                            onTap: () => _pickSky(b),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _PickerLabel('WEATHER'),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final w in ShareWeather.values)
                          _WeatherChip(
                            weather: w,
                            selected: w == _weather,
                            onTap: () => _pickWeather(w),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _share,
                        icon: _busy
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(_busy ? 'Preparing…' : 'Share image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spiritualGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  final String text;

  const _PickerLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.45))
            .copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final ShareWeather weather;
  final bool selected;
  final VoidCallback onTap;

  const _WeatherChip({required this.weather, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.spiritualGold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.spiritualGold.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(weather.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                weather.label,
                style: AppTextStyles.small(color: color, weight: selected ? FontWeight.w600 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundSwatch extends StatelessWidget {
  final ShareBackground background;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundSwatch({required this.background, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.12),
                  width: selected ? 2 : 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: background.colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              background.label,
              style: AppTextStyles.tiny(
                color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.55),
              ).copyWith(fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shareable card: 360pt wide, rendered at 3× for a 1080px image.
class VerseShareCard extends StatelessWidget {
  final VerseShare share;
  final QuranScript script;
  final bool translation;
  final bool transliteration;
  final ShareBackground background;
  final ShareWeather weather;

  const VerseShareCard({
    super.key,
    required this.share,
    required this.script,
    required this.translation,
    required this.transliteration,
    required this.background,
    this.weather = ShareWeather.clear,
  });

  static const double width = 360;

  /// Western digits → Arabic-Indic, for the ayah-end ornament.
  static String _arabicDigits(int n) =>
      n.toString().split('').map((d) => String.fromCharCode(0x0660 + int.parse(d))).join();

  @override
  Widget build(BuildContext context) {
    final count = share.verses.length;
    final totalLength = share.verses.fold<int>(0, (sum, v) => sum + v.textUthmani.length);
    // Short passages read best large; long ones need to fit on one image.
    final arabicSize = totalLength > 900
        ? 20.0
        : totalLength > 400
            ? 23.0
            : 27.0;
    final accent = background.accent;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned.fill(child: ShareSky(background: background, weather: weather)),

          // Content inside a hairline frame
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Surah title between ornamental rules
                Row(
                  children: [
                    Expanded(child: _Rule(color: accent, reverse: true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        share.surah.nameArabic,
                        style: AppTextStyles.arabic(color: accent, size: 30).copyWith(height: 1.3),
                      ),
                    ),
                    Expanded(child: _Rule(color: accent)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${share.surah.nameTransliteration.toUpperCase()}   ·   ${share.reference}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < count; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('۞', style: TextStyle(fontSize: 12, color: accent.withValues(alpha: 0.6))),
                      ),
                    ),
                  Text.rich(
                    TextSpan(
                      text: '${share.verses[i].textUthmani.trim()} ',
                      children: [
                        // The ayah-number brackets come from Amiri: the
                        // Uthmanic Hafs font has no ﴿﴾ glyphs.
                        TextSpan(
                          text: '﴿${_arabicDigits(share.verses[i].verseNumber)}﴾',
                          style: AppTextStyles.arabic(color: accent, size: arabicSize * 0.8),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.arabic(color: Colors.white, size: arabicSize, script: script).copyWith(
                      height: 1.95,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
                    ),
                  ),
                  if (transliteration && (share.verses[i].transliterationText ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      share.verses[i].transliterationText!.trim(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (translation && (share.verses[i].translationText ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      share.verses[i].translationText!.trim(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: totalLength > 900 ? 12.5 : 13.5,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 26),
                Container(height: 0.6, color: Colors.white.withValues(alpha: 0.16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _WirdMark(size: 26),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wird',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'Prayer & Quran companion',
                          style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Quran ${share.reference}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
                          ),
                          if (translation && share.verses.first.translationName != null)
                            Text(
                              share.verses.first.translationName!,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin rule that fades in toward the surah title, with a small diamond.
class _Rule extends StatelessWidget {
  final Color color;
  final bool reverse;

  const _Rule({required this.color, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reverse
                ? [Colors.transparent, color.withValues(alpha: 0.7)]
                : [color.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
      ),
    );
    final diamond = Transform.rotate(
      angle: 0.785398,
      child: Container(width: 4, height: 4, color: color.withValues(alpha: 0.8)),
    );
    return Row(children: reverse ? [line, const SizedBox(width: 4), diamond] : [diamond, const SizedBox(width: 4), line]);
  }
}

/// The Wird app icon. wird2.png has a dark backdrop around the icon tile, so
/// it's scaled up and clipped to show just the tile.
class _WirdMark extends StatelessWidget {
  final double size;

  const _WirdMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          maxWidth: size * 2.1,
          maxHeight: size * 2.1,
          child: Image.asset('assets/wird2.png', width: size * 2.1, height: size * 2.1, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
