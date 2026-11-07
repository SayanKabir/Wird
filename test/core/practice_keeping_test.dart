import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/dhikr/dhikr_catalog.dart';
import 'package:wird2/core/repositories/sunnah_progress_repository.dart';
import 'package:wird2/core/repositories/sunnah_repository.dart';
import 'package:wird2/core/repositories/tasbih_repository.dart';
import 'package:wird2/features/sunnah/bloc/sunnah_bloc.dart';
import 'package:wird2/features/sunnah/practice_keeper.dart';
import 'package:wird2/features/tasbih/bloc/tasbih_bloc.dart';
import 'package:wird2/models/sunnah.dart';
import 'package:wird2/models/sunnah_progress.dart';
import 'package:wird2/models/tasbih.dart';

import '../helpers/test_hive.dart';

final _sunnahs = SunnahRepository().getAllSunnahsSync();
Sunnah _titled(String title) => _sunnahs.firstWhere((s) => s.title == title);

final _sayyid = _titled('Say Sayyid al-Istighfar morning and evening');
final _subhanallah = _titled('Say SubhanAllah 33 times after prayer');
final _istighfar = _titled('Istighfar 100 times daily');
final _fatimah = _titled('Tasbih of Fatimah');
final _morning = _titled('Complete Morning Azkar');
final _sleep = _titled('Complete Before-Sleep Azkar');

Tasbih _counter(String id, int target, {int today = 0}) => Tasbih(
      id: id,
      name: id,
      targetCount: target,
      lastUpdated: DateTime.now(),
    ).tallied(today);

void main() {
  group('which dhikr keeps which Sunnah', () {
    test('a counter keeps its own dhikr, a session keeps the azkar', () {
      expect(DhikrCatalog.counterKeeping(_sayyid), 'sayyid_istighfar');
      expect(DhikrCatalog.counterKeeping(_subhanallah), 'subhanallah');
      expect(DhikrCatalog.counterKeeping(_istighfar), 'astaghfirullah');
      // These belong to sessions, not to the counters that share their words.
      expect(DhikrCatalog.counterKeeping(_fatimah), isNull);
      expect(DhikrCatalog.counterKeeping(_morning), isNull);

      expect(DhikrCatalog.keptBySession('morning', _sunnahs), {_morning.id});
      expect(DhikrCatalog.keptBySession('before_sleep', _sunnahs), {_sleep.id});
      expect(DhikrCatalog.keptBySession('fatimah', _sunnahs), {_fatimah.id});
    });

    test('kept once the count the Sunnah asks for is said today', () {
      Set<String> kept(List<Tasbih> counters) => DhikrCatalog.keptByCounters(
            sunnahs: _sunnahs,
            practiceIds: [_sayyid.id, _subhanallah.id, _istighfar.id],
            counters: counters,
          );
      expect(kept([_counter('subhanallah', 33, today: 32)]), isEmpty);
      expect(kept([_counter('subhanallah', 33, today: 33)]), {_subhanallah.id});
      // The Sunnah's own count wins over a smaller round.
      expect(kept([_counter('astaghfirullah', 33, today: 99)]), isEmpty);
      expect(kept([_counter('astaghfirullah', 33, today: 100)]), {_istighfar.id});
      // No count of its own: one full round.
      expect(kept([_counter('sayyid_istighfar', 1, today: 1)]), {_sayyid.id});
    });

    test('only Sunnahs in the practice', () {
      expect(
        DhikrCatalog.keptByCounters(
          sunnahs: _sunnahs,
          practiceIds: const [],
          counters: [_counter('subhanallah', 33, today: 33)],
        ),
        isEmpty,
      );
    });

    test('yesterday\'s count doesn\'t keep today', () {
      final yesterday = Tasbih(id: 'subhanallah', name: 's', targetCount: 33, lastUpdated: DateTime.now())
          .tallied(33, now: DateTime.now().subtract(const Duration(days: 1)));
      expect(
        DhikrCatalog.keptByCounters(sunnahs: _sunnahs, practiceIds: [_subhanallah.id], counters: [yesterday]),
        isEmpty,
      );
    });
  });

  group('counting on the dhikr page', () {
    testWidgets('ticks the practice the moment the count is reached, and respects an untick', (tester) async {
      final progress = _MemoryProgress(SunnahProgress.empty().copyWith(practiceIds: [_sayyid.id, _subhanallah.id]));
      final sunnah = SunnahBloc(repository: _Sunnahs(), progressRepository: progress)..add(LoadSunnahs());
      final tasbih = TasbihBloc(repository: _Counters([_counter('subhanallah', 33), _counter('sayyid_istighfar', 1)]))
        ..add(LoadTasbihs());
      await tester.pumpWidget(MultiBlocProvider(
        providers: [BlocProvider.value(value: sunnah), BlocProvider.value(value: tasbih)],
        child: const PracticeKeeper(child: SizedBox()),
      ));
      await tester.pump();
      bool done(Sunnah s) => (sunnah.state as SunnahLoaded).progress.isPracticedToday(s.id);

      tasbih.add(const CounterTapped('sayyid_istighfar'));
      await tester.pump();
      await tester.pump();
      expect(done(_sayyid), isTrue);

      for (var i = 0; i < 32; i++) {
        tasbih.add(const CounterTapped('subhanallah'));
        await tester.pump();
      }
      await tester.pump();
      expect(done(_subhanallah), isFalse);
      tasbih.add(const CounterTapped('subhanallah'));
      await tester.pump();
      await tester.pump();
      expect(done(_subhanallah), isTrue);

      // Taken back by hand, it stays off while counting goes on.
      sunnah.add(ToggleSunnahToday(_subhanallah.id));
      await tester.pump();
      expect(done(_subhanallah), isFalse);
      tasbih.add(const CounterTapped('subhanallah'));
      await tester.pump();
      await tester.pump();
      expect(done(_subhanallah), isFalse);

      // Closing a bloc inside the fake clock never completes; let them go.
      sunnah.close();
      tasbih.close();
    });
  });

  // Last: it opens real storage, which the widget test above must not see.
  group('SunnahProgressRepository.markToday', () {
    late Directory dir;
    setUp(() async => dir = await openTestStorage());
    tearDown(() => closeTestStorage(dir));

    test('marks each once and moves the streak once', () async {
      final repo = SunnahProgressRepository();
      var p = await repo.markToday(['a', 'b']);
      expect(p.isPracticedToday('a'), isTrue);
      expect(p.isPracticedToday('b'), isTrue);
      expect(p.currentStreak, 1);
      p = await repo.markToday(['a']);
      expect(p.practiceCountsBySunnah['a'], 1, reason: 'already marked today');
      expect(p.totalPracticeActions, 2);
      expect((await repo.getProgress()).isPracticedToday('b'), isTrue);
    });
  });
}

class _Sunnahs extends SunnahRepository {
  @override
  Future<Sunnah> getWeeklySunnah() async => _sunnahs.first;
}

class _Counters extends TasbihRepository {
  final List<Tasbih> counters;
  _Counters(this.counters);

  @override
  Future<void> init() async {}

  @override
  Future<List<Tasbih>> getAllTasbihs() async => counters;

  @override
  Future<void> saveTasbih(Tasbih tasbih) async {}
}

/// Progress kept in memory: no Hive inside the fake test clock.
class _MemoryProgress extends SunnahProgressRepository {
  SunnahProgress progress;
  _MemoryProgress(this.progress);

  @override
  Future<SunnahProgress> getProgress() async => progress;

  @override
  Future<List<String>> seedDefaultPractice() async => const [];

  Map<String, String> _set(String id, String? day) {
    final m = Map<String, String>.from(progress.lastPracticedDayBySunnah);
    day == null ? m.remove(id) : m[id] = day;
    return m;
  }

  @override
  Future<SunnahProgress> markToday(Iterable<String> sunnahIds, {DateTime? at}) async {
    for (final id in sunnahIds) {
      progress = progress.copyWith(lastPracticedDayBySunnah: _set(id, SunnahProgress.dateKey(at ?? DateTime.now())));
    }
    return progress;
  }

  @override
  Future<SunnahProgress> toggleToday(String sunnahId, {DateTime? at}) async {
    final today = progress.isPracticedToday(sunnahId, now: at);
    progress = progress.copyWith(
        lastPracticedDayBySunnah: _set(sunnahId, today ? null : SunnahProgress.dateKey(at ?? DateTime.now())));
    return progress;
  }
}
