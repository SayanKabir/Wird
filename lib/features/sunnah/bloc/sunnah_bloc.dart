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
    on<MarkSunnahPracticed>(_onMarkSunnahPracticed);
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

  Future<void> _onMarkSunnahPracticed(
    MarkSunnahPracticed event,
    Emitter<SunnahState> emit,
  ) async {
    final current = state;
    if (current is! SunnahLoaded) return;

    try {
      final updatedProgress = await _progressRepository.markPracticed(
        event.sunnahId,
      );
      emit(current.copyWith(progress: updatedProgress));
    } catch (e) {
      emit(SunnahError(e.toString()));
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
