import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:wird2/features/home/bloc/prayer_bloc.dart';
import 'package:wird2/features/quran/sharing/verse_share.dart';
import 'package:wird2/features/quran/sharing/verse_share_sheet.dart';
import 'package:wird2/models/settings.dart';
import 'package:wird2/models/surah.dart';
import 'package:wird2/models/verse.dart';

import '../settings_integration_test.mocks.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late List<MethodCall> calls;
  late bool granted;
  setUp(() {
    calls = [];
    granted = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('gal'),
      (call) async {
        calls.add(call);
        return switch (call.method) {
          'hasAccess' || 'requestAccess' => granted,
          _ => null,
        };
      },
    );
  });

  Future<void> pumpPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bloc = MockPrayerBloc();
    when(bloc.state).thenReturn(PrayerLoading());
    when(bloc.stream).thenAnswer((_) => const Stream.empty());
    final share = VerseShare(
      surah: Surah(id: 112, nameArabic: 'الإخلاص', nameTranslation: 'Sincerity', nameTransliteration: 'Al-Ikhlas',
          versesCount: 4, revelationPlace: 'makkah', revelationOrder: 22, pages: const [604]),
      verses: [Verse(surahId: 112, verseNumber: 1, verseKey: '112:1', textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ', page: 604, juz: 30)],
    );
    await tester.pumpWidget(BlocProvider<PrayerBloc>.value(
      value: bloc,
      child: MaterialApp(
        home: VerseImagePreview(share: share, script: QuranScript.uthmani, translation: false, transliteration: false),
      ),
    ));
    await tester.pump();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder button) async {
    await tester.tap(button);
    // Rendering the image and the platform calls are real async work.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('offers Save next to Share image', (tester) async {
    await pumpPreview(tester);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share image'), findsOneWidget);
  });

  testWidgets('saves a PNG into the Wird album', (tester) async {
    await pumpPreview(tester);
    await tapAndSettle(tester, find.text('Save'));

    final put = calls.singleWhere((c) => c.method == 'putImageBytes');
    final args = put.arguments as Map;
    expect(args['album'], 'Wird');
    expect(args['name'], 'quran-112-1');
    final bytes = args['bytes'] as Uint8List;
    expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
    expect(find.text('Saved to the Wird album'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('says what to do when photo access is refused', (tester) async {
    granted = false;
    await pumpPreview(tester);
    await tapAndSettle(tester, find.text('Save'));
    expect(calls.where((c) => c.method == 'putImageBytes'), isEmpty);
    expect(find.text('Allow Wird to add photos to save the image'), findsOneWidget);
  });
}
