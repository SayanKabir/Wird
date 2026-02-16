import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/colors.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/home/bloc/prayer_bloc.dart';
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/qibla/screens/qibla_screen.dart';
import 'features/statistics/screens/statistics_screen.dart';
import 'features/islamic_calendar/screens/islamic_calendar_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/sunnah/bloc/sunnah_bloc.dart';
import 'core/repositories/sunnah_repository.dart';
import 'core/repositories/sunnah_progress_repository.dart';
import 'features/azkar/bloc/azkar_bloc.dart';
import 'core/repositories/azkar_repository.dart';
import 'features/tasbih/bloc/tasbih_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/repositories/tasbih_repository.dart';
import 'models/sunnah.dart';
import 'models/azkar.dart';
import 'models/tasbih.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  // Register Hive Adapters
  Hive.registerAdapter(SunnahDifficultyAdapter());
  Hive.registerAdapter(SunnahFrequencyAdapter());
  Hive.registerAdapter(SunnahAdapter());
  Hive.registerAdapter(AzkarCategoryAdapter());
  Hive.registerAdapter(AzkarAdapter());
  Hive.registerAdapter(TasbihAdapter());

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WirdApp());
}

class WirdApp extends StatelessWidget {
  const WirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final isOnboardingComplete = storageService.isOnboardingCompleted();

    return MultiBlocProvider(
      providers: [
        RepositoryProvider(create: (context) => SunnahRepository()),
        RepositoryProvider(create: (context) => SunnahProgressRepository()),
        RepositoryProvider(create: (context) => AzkarRepository()),
        RepositoryProvider(create: (context) => TasbihRepository()),
        BlocProvider<PrayerBloc>(
          create: (context) => PrayerBloc()..add(LoadPrayers()),
        ),
        BlocProvider<SunnahBloc>(
          create: (context) => SunnahBloc(
            repository: context.read<SunnahRepository>(),
            progressRepository: context.read<SunnahProgressRepository>(),
          )..add(LoadSunnahs()),
        ),
        BlocProvider<AzkarBloc>(
          create: (context) => AzkarBloc(
            repository: context.read<AzkarRepository>(),
          )..add(LoadAzkarCategories()),
        ),
        BlocProvider<TasbihBloc>(
          create: (context) => TasbihBloc(
            repository: context.read<TasbihRepository>(),
          )..add(LoadTasbihs()),
        ),
      ],
      child: MaterialApp(
        title: 'Wird',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: isOnboardingComplete ? '/home' : '/onboarding',
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/qibla': (context) => const QiblaScreen(),
          '/islamic-calendar': (context) => const IslamicCalendarScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.buttonPrimary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.buttonPrimary,
        secondary: AppColors.activeGlow,
        surface: AppColors.cardBackground,
        error: AppColors.statusMissed,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.buttonPrimary,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
