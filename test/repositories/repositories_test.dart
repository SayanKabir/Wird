import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wird2/core/dhikr/dhikr_catalog.dart';
import 'package:wird2/core/repositories/quran_progress_repository.dart';
import 'package:wird2/core/repositories/sunnah_progress_repository.dart';
import 'package:wird2/core/repositories/tasbih_repository.dart';
import 'package:wird2/features/tasbih/bloc/tasbih_bloc.dart';
import 'package:wird2/models/quran_progress.dart';
import 'package:wird2/models/sunnah_progress.dart';
import 'package:wird2/models/tasbih.dart';

/// Each test gets an empty Hive directory, so nothing leaks between them.
void main() {
  late Directory dir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(25)) Hive.registerAdapter(TasbihAdapter());
    if (!Hive.isAdapterRegistered(33)) Hive.registerAdapter(QuranProgressAdapter());
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wird_hive_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  group('SunnahProgressRepository', () {
    final repo = SunnahProgressRepository();
    final mon = DateTime(2026, 10, 26, 9);
    final tue = DateTime(2026, 10, 27, 9);
    final thu = DateTime(2026, 10, 29, 9);

    test('starts empty', () async {
      final p = await repo.getProgress();
      expect(p, SunnahProgress.empty());
    });

    test('ticking on consecutive days builds a streak; a gap restarts it', () async {
      await repo.toggleToday('smile', at: mon);
      var p = await repo.toggleToday('smile', at: tue);
      expect(p.currentStreak, 2);
      expect(p.longestStreak, 2);
      p = await repo.toggleToday('smile', at: thu);
      expect(p.currentStreak, 1);
      expect(p.longestStreak, 2);
      expect(p.practiceCountsBySunnah['smile'], 3);
      expect(p.totalPracticeActions, 3);
    });

    test('a second sunnah on the same day does not move the streak', () async {
      await repo.toggleToday('smile', at: tue);
      final p = await repo.toggleToday('miswak', at: tue);
      expect(p.currentStreak, 1);
      expect(p.totalPracticeActions, 2);
      expect(p.isPracticedToday('miswak', now: tue), isTrue);
      expect(p.practiceLog[SunnahProgress.dateKey(tue)], ['smile', 'miswak']);
    });

    test("undoing today's only tick puts the streak back as it was", () async {
      await repo.toggleToday('smile', at: mon);
      await repo.toggleToday('smile', at: tue);
      final undone = await repo.toggleToday('smile', at: tue);
      expect(undone.currentStreak, 1);
      expect(undone.longestStreak, 1);
      expect(undone.lastPracticeDateKey, SunnahProgress.dateKey(mon));
      expect(undone.isPracticedToday('smile', now: tue), isFalse);
      // Falls back to the earlier day it was kept.
      expect(undone.lastPracticedDayBySunnah['smile'], SunnahProgress.dateKey(mon));
      expect(undone.practiceCountsBySunnah['smile'], 1);
      expect(undone.totalPracticeActions, 1);
    });

    test('undoing one of two ticks today keeps the streak', () async {
      await repo.toggleToday('smile', at: mon);
      await repo.toggleToday('smile', at: tue);
      await repo.toggleToday('miswak', at: tue);
      final p = await repo.toggleToday('miswak', at: tue);
      expect(p.currentStreak, 2);
      expect(p.lastPracticeDateKey, SunnahProgress.dateKey(tue));
      expect(p.practiceCountsBySunnah.containsKey('miswak'), isFalse);
    });

    test('tick, untick, tick again gives the same streak', () async {
      await repo.toggleToday('smile', at: mon);
      final first = await repo.toggleToday('smile', at: tue);
      await repo.toggleToday('smile', at: tue);
      final again = await repo.toggleToday('smile', at: tue);
      expect(again.currentStreak, first.currentStreak);
      expect(again.longestStreak, first.longestStreak);
    });

    test('practice list toggles in and out', () async {
      var p = await repo.togglePractice('smile');
      expect(p.isInPractice('smile'), isTrue);
      p = await repo.togglePractice('miswak');
      expect(p.practiceIds, ['smile', 'miswak']);
      p = await repo.togglePractice('smile');
      expect(p.practiceIds, ['miswak']);
      expect((await repo.getProgress()).practiceIds, ['miswak']);
    });

    test('old-format data with missing fields still loads', () async {
      final box = await Hive.openBox<dynamic>('sunnah_progress');
      await box.put('progress', {'currentStreak': 4, 'totalPoints': 120});
      final p = await repo.getProgress();
      expect(p.currentStreak, 4);
      expect(p.totalPoints, 120);
      expect(p.practiceIds, isEmpty);
      expect(p.practiceLog, isEmpty);
    });

    test('garbage in the box reads as empty progress', () async {
      final box = await Hive.openBox<dynamic>('sunnah_progress');
      await box.put('progress', 'not a map');
      expect(await repo.getProgress(), SunnahProgress.empty());
    });
  });

  group('QuranProgressRepository', () {
    final repo = QuranProgressRepository();
    final d1 = DateTime(2026, 10, 25, 21);
    final d2 = DateTime(2026, 10, 26, 6);
    final d4 = DateTime(2026, 10, 28, 6);

    test('reading on consecutive days builds a streak', () async {
      await repo.markVersesRead(10, at: d1);
      await repo.markVersesRead(5, at: d1);
      var p = await repo.markVersesRead(7, at: d2);
      expect(p.totalVersesRead, 22);
      expect(p.currentStreak, 2);
      expect(p.daysRead, 2);
      expect(p.versesReadByDay['2026-10-25'], 15);

      p = await repo.markVersesRead(1, at: d4);
      expect(p.currentStreak, 1);
      expect(p.longestStreak, 2);
      expect(p.daysRead, 3);
    });

    test('zero or negative counts change nothing', () async {
      await repo.markVersesRead(3, at: d1);
      final p = await repo.markVersesRead(0, at: d2);
      expect(p.totalVersesRead, 3);
      expect((await repo.markVersesRead(-5, at: d2)).totalVersesRead, 3);
      expect(p.lastReadDateKey, '2026-10-25');
    });

    test('progress survives closing and reopening Hive', () async {
      await repo.markVersesRead(12, at: d1);
      await Hive.close();
      Hive.init(dir.path);
      final p = await repo.getProgress();
      expect(p, isA<QuranProgress>());
      expect(p.totalVersesRead, 12);
    });
  });

  group('TasbihRepository', () {
    final repo = TasbihRepository();

    test('built-in counters are backfilled once', () async {
      await repo.init();
      final first = await repo.getAllTasbihs();
      final ids = first.map((t) => t.id).toSet();
      expect(ids, containsAll(DhikrCatalog.builtInCounterIds));
      final second = await repo.getAllTasbihs();
      expect(second, hasLength(first.length));
    });

    test('save and delete', () async {
      await repo.init();
      final t = Tasbih(id: 'custom_1', name: 'Mine', targetCount: 7, lastUpdated: DateTime(2026));
      await repo.saveTasbih(t);
      expect((await repo.getAllTasbihs()).any((x) => x.id == 'custom_1'), isTrue);
      await repo.deleteTasbih('custom_1');
      expect((await repo.getAllTasbihs()).any((x) => x.id == 'custom_1'), isFalse);
    });
  });

  group('DhikrSessionStore', () {
    final store = DhikrSessionStore();
    final at = DateTime(2026, 10, 27, 13, 0);

    setUp(() => TasbihRepository().init());

    test('resumes within two hours on the same day', () async {
      await store.savePosition('after_prayer', 2, 11, now: at);
      expect(store.resumePoint('after_prayer', now: at.add(const Duration(minutes: 90))), (2, 11));
      expect(store.resumePoint('after_prayer', now: at.add(const Duration(hours: 3))), isNull);
      expect(store.resumePoint('after_prayer', now: at.add(const Duration(days: 1))), isNull);
    });

    test('an untouched position is not offered', () async {
      await store.savePosition('morning', 0, 0, now: at);
      expect(store.resumePoint('morning', now: at), isNull);
    });

    test('done clears the position and is remembered for the day only', () async {
      await store.savePosition('evening', 3, 4, now: at);
      await store.markDone('evening', now: at);
      expect(store.isDoneToday('evening', now: at), isTrue);
      expect(store.resumePoint('evening', now: at), isNull);
      expect(store.isDoneToday('evening', now: at.add(const Duration(days: 1))), isFalse);
      // Saving a new position later that day keeps the done flag.
      await store.savePosition('evening', 1, 1, now: at.add(const Duration(minutes: 5)));
      expect(store.isDoneToday('evening', now: at), isTrue);
    });
  });

  group('TasbihBloc', () {
    test('loads, taps, undoes, adds, edits and deletes', () async {
      final bloc = TasbihBloc(repository: TasbihRepository());
      addTearDown(bloc.close);

      Future<TasbihLoaded> next() => bloc.stream.firstWhere((s) => s is TasbihLoaded).then((s) => s as TasbihLoaded);

      bloc.add(LoadTasbihs());
      var state = await next();
      expect(state.byId('subhanallah'), isNotNull);

      bloc.add(const CounterTapped('subhanallah'));
      state = await next();
      expect(state.byId('subhanallah')!.currentCount, 1);

      bloc.add(const CounterUndone('subhanallah'));
      state = await next();
      expect(state.byId('subhanallah')!.currentCount, 0);

      bloc.add(const AddTasbih('Mine', 11));
      state = await next();
      final mine = state.tasbihs.firstWhere((t) => t.name == 'Mine');
      expect(mine.targetCount, 11);

      bloc.add(EditTasbih(mine.id, 'Renamed', 21));
      state = await next();
      expect(state.byId(mine.id)!.name, 'Renamed');
      expect(state.byId(mine.id)!.targetCount, 21);

      bloc.add(DeleteTasbih(mine.id));
      state = await next();
      expect(state.byId(mine.id), isNull);

      // Persisted: a fresh bloc sees the same counts. The bloc emits before it
      // saves, so let the last write land first.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final reloaded = TasbihBloc(repository: TasbihRepository());
      addTearDown(reloaded.close);
      reloaded.add(LoadTasbihs());
      final fresh = await reloaded.stream.firstWhere((s) => s is TasbihLoaded) as TasbihLoaded;
      expect(fresh.byId(mine.id), isNull);
      expect(fresh.byId('subhanallah')!.totalCount, 0);
    });

    test('events for an unknown counter are ignored', () async {
      final bloc = TasbihBloc(repository: TasbihRepository());
      addTearDown(bloc.close);
      bloc.add(LoadTasbihs());
      final loaded = await bloc.stream.firstWhere((s) => s is TasbihLoaded);
      bloc.add(const CounterTapped('does_not_exist'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, loaded);
    });
  });
}
