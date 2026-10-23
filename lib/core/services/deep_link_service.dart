import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/quran/screens/surah_reading_screen.dart';
import '../../features/quran/sharing/verse_share.dart';
import '../repositories/quran_repository.dart';
import 'storage_service.dart';

/// Opens the Quran reader when Wird is launched from a shared verse link
/// (https://quran.com/2/255-257), whether the app was closed or running.
///
/// Android only: links reach the app through MainActivity's intent filter.
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.SayanKabir.wird2/links');

  final GlobalKey<NavigatorState> navigatorKey;
  final QuranRepository quranRepository;

  DeepLinkService({required this.navigatorKey, required this.quranRepository});

  Future<void> init() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink' && call.arguments is String) {
        _open(call.arguments as String);
      }
    });
    try {
      final initial = await _channel.invokeMethod<String>('getInitialLink');
      // Wait for the first route so the reader opens on top of home.
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial));
      }
    } on PlatformException catch (e) {
      debugPrint('[DeepLink] initial link unavailable: $e');
    }
  }

  void _open(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ref = verseRefFromLink(uri, surahs: quranRepository.surahs);
    // A link can't skip setup: without onboarding there are no prayer
    // settings to come back to.
    if (ref == null || !StorageService().isOnboardingCompleted()) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    debugPrint('[DeepLink] opening $ref');
    navigator.push(MaterialPageRoute(
      builder: (_) => SurahReadingScreen(
        surahId: ref.surah,
        surahName: quranRepository.surahById(ref.surah)?.nameTransliteration,
        initialVerse: ref.verse,
        initialVerseEnd: ref.toVerse,
      ),
    ));
  }
}
