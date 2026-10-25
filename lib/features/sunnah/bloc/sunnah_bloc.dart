import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/repositories/sunnah_progress_repository.dart';
import 'sunnah_event_state.dart';

export 'sunnah_event_state.dart';

class SunnahBloc extends Bloc<SunnahEvent, SunnahState> {
  final SunnahRepository _repository;
  final SunnahProgressRepository _progressRepository;

  SunnahBloc({
    required SunnahRepository repository,
    required SunnahProgressRepository progressRepository,
  })  : _repository = repository,
        _progressRepository = progressRepository,
        super(SunnahLoading()) {
    on<LoadSunnahs>(_onLoadSunnahs);
    on<ToggleSunnahToday>(_onToggleToday);
    on<ToggleSunnahPractice>(_onTogglePractice);
    on<SkipWeeklySunnah>(_onSkipWeeklySunnah);
  }

  Future<void> _onLoadSunnahs(
    LoadSunnahs event,
    Emitter<SunnahState> emit,
  ) async {
    try {
      if (state is! SunnahLoaded) {
        emit(SunnahLoading());
      }

      final sunnahsFuture = _repository.getAllSunnahs();
      final weeklySunnahFuture = _repository.getWeeklySunnah();
      final progressFuture = _progressRepository.getProgress();
      final sunnahs = await sunnahsFuture;
      final weeklySunnah = await weeklySunnahFuture;
      final progress = await progressFuture;

      final currentState = state;
      if (currentState is SunnahLoaded &&
          identical(currentState.sunnahs, sunnahs) &&
          currentState.weeklySunnah?.id == weeklySunnah.id &&
          currentState.progress == progress) {
        return;
      }

      emit(SunnahLoaded(
        sunnahs: sunnahs,
        weeklySunnah: weeklySunnah,
        progress: progress,
      ));
    } catch (e) {
      emit(SunnahError(e.toString()));
    }
  }

  Future<void> _onToggleToday(
    ToggleSunnahToday event,
    Emitter<SunnahState> emit,
  ) async {
    final current = state;
    if (current is! SunnahLoaded) return;

    try {
      final updated = await _progressRepository.toggleToday(event.sunnahId);
      emit(current.copyWith(progress: updated));
    } catch (e) {
      // Keep the screen as it was; the tick simply doesn't land.
      debugPrint('[SunnahBloc] toggleToday failed: $e');
    }
  }

  Future<void> _onTogglePractice(
    ToggleSunnahPractice event,
    Emitter<SunnahState> emit,
  ) async {
    final current = state;
    if (current is! SunnahLoaded) return;

    try {
      final updated = await _progressRepository.togglePractice(event.sunnahId);
      emit(current.copyWith(progress: updated));
    } catch (e) {
      debugPrint('[SunnahBloc] togglePractice failed: $e');
    }
  }

  Future<void> _onSkipWeeklySunnah(
    SkipWeeklySunnah event,
    Emitter<SunnahState> emit,
  ) async {
    final current = state;
    if (current is! SunnahLoaded) return;

    try {
      final newWeekly = await _repository.skipWeeklySunnah();
      emit(current.copyWith(weeklySunnah: newWeekly));
    } catch (e) {
      // silently ignore skip errors
    }
  }
}
