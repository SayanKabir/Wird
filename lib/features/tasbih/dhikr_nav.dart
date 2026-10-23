import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/repositories/tasbih_repository.dart';
import '../../core/services/prayer_service.dart';
import '../home/bloc/prayer_bloc.dart';
import 'screens/counter_screen.dart';
import 'screens/dhikr_hub_screen.dart';
import 'screens/session_screen.dart';

/// Entry points into the dhikr section, so callers don't build routes.
class DhikrNav {
  DhikrNav._();

  static Future<void> openHub(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DhikrHubScreen()));

  static Future<void> openSession(BuildContext context, String sessionId) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionScreen(sessionId: sessionId)));

  static Future<void> openCounter(BuildContext context, String counterId) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CounterScreen(counterId: counterId)));

  /// The session that suits this time of day. Once the morning or evening
  /// azkar are done, the after-prayer dhikr takes their place.
  static String nowSessionId(BuildContext context) {
    final state = context.read<PrayerBloc>().state;
    final period = state is PrayerLoaded ? state.prayerPeriod : null;
    final store = DhikrSessionStore();
    switch (period) {
      case PrayerPeriod.fajr:
      case PrayerPeriod.sunrise:
        return store.isDoneToday('morning') ? 'after_prayer' : 'morning';
      case PrayerPeriod.asr:
      case PrayerPeriod.maghrib:
        return store.isDoneToday('evening') ? 'after_prayer' : 'evening';
      case PrayerPeriod.isha:
      case PrayerPeriod.tahajjud:
        return 'before_sleep';
      case PrayerPeriod.dhuhr:
      case null:
        return 'after_prayer';
    }
  }
}
