import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../models/tasbih.dart';
import 'tasbih_event_state.dart';

export 'tasbih_event_state.dart';

/// Holds every dhikr counter. Handlers emit the new state before awaiting the
/// write, so rapid taps (which bloc runs concurrently) each build on the
/// previous tap rather than racing it.
class TasbihBloc extends Bloc<TasbihEvent, TasbihState> {
  final TasbihRepository _repository;

  TasbihBloc({required TasbihRepository repository})
      : _repository = repository,
        super(TasbihInitial()) {
    on<LoadTasbihs>(_onLoad);
    on<CounterTapped>((e, emit) => _update(e.id, emit, (t) => t.tapped()));
    on<CounterUndone>((e, emit) => _update(e.id, emit, (t) => t.undone()));
    on<CounterReset>((e, emit) => _update(e.id, emit, (t) => t.reset()));
    on<CounterTallied>((e, emit) => _update(e.id, emit, (t) => t.tallied(e.delta)));
    on<EditTasbih>((e, emit) => _update(
          e.id,
          emit,
          (t) => t.copyWith(
            name: e.name,
            targetCount: e.target,
            // A smaller target can leave the round overfull; cap it.
            currentCount: t.currentCount > e.target ? e.target : t.currentCount,
          ),
        ));
    on<AddTasbih>(_onAdd);
    on<DeleteTasbih>(_onDelete);
  }

  Future<void> _onLoad(LoadTasbihs event, Emitter<TasbihState> emit) async {
    try {
      if (state is! TasbihLoaded) emit(TasbihLoading());
      await _repository.init();
      emit(TasbihLoaded(await _repository.getAllTasbihs()));
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  Future<void> _update(String id, Emitter<TasbihState> emit, Tasbih Function(Tasbih) change) async {
    final current = state;
    if (current is! TasbihLoaded) return;
    final existing = current.byId(id);
    if (existing == null) return;
    final updated = change(existing);
    if (updated == existing) return;
    emit(TasbihLoaded([for (final t in current.tasbihs) t.id == id ? updated : t]));
    try {
      await _repository.saveTasbih(updated);
    } catch (e) {
      debugPrint('[TasbihBloc] save failed for $id: $e');
    }
  }

  Future<void> _onAdd(AddTasbih event, Emitter<TasbihState> emit) async {
    final current = state;
    if (current is! TasbihLoaded) return;
    final created = Tasbih(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: event.name,
      targetCount: event.target,
      lastUpdated: DateTime.now(),
    );
    emit(TasbihLoaded([...current.tasbihs, created]));
    try {
      await _repository.saveTasbih(created);
    } catch (e) {
      debugPrint('[TasbihBloc] add failed: $e');
    }
  }

  Future<void> _onDelete(DeleteTasbih event, Emitter<TasbihState> emit) async {
    final current = state;
    if (current is! TasbihLoaded) return;
    emit(TasbihLoaded(current.tasbihs.where((t) => t.id != event.id).toList()));
    try {
      await _repository.deleteTasbih(event.id);
    } catch (e) {
      debugPrint('[TasbihBloc] delete failed: $e');
    }
  }
}
