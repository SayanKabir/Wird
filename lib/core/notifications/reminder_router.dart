import 'package:flutter/material.dart';

import '../../features/quran/screens/surah_reading_screen.dart';
import '../../features/tasbih/screens/session_screen.dart';
import '../../widgets/common/app_route.dart';
import '../repositories/quran_repository.dart';
import '../services/storage_service.dart';

/// Opens what a tapped reminder points at, on top of home:
/// `session:<id>` a guided dhikr session, `quran:<surah>` the reader,
/// `quran:last` wherever reading stopped. `sunnah` and anything unknown just
/// bring the app forward.
void openReminderTarget(String target, {required NavigatorState? navigator, required QuranRepository quran}) {
  if (navigator == null || !StorageService().isOnboardingCompleted()) return;
  final parts = target.split(':');
  switch (parts.first) {
    case 'session' when parts.length > 1:
      navigator.push(AppRoute(builder: (_) => SessionScreen(sessionId: parts[1])));
    case 'quran' when parts.length > 1:
      final last = parts[1] == 'last' ? quran.getLastRead() : null;
      final surahId = last?.surahId ?? int.tryParse(parts[1]) ?? 1;
      navigator.push(AppRoute(
        builder: (_) => SurahReadingScreen(
          surahId: surahId,
          surahName: quran.surahById(surahId)?.nameTransliteration,
          initialVerse: last?.verseNumber,
        ),
      ));
  }
}
