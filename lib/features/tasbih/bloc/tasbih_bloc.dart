import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/tasbih_repository.dart';
import '../../../models/tasbih.dart';
import 'tasbih_event_state.dart';

export 'tasbih_event_state.dart';

class TasbihBloc extends Bloc<TasbihEvent, TasbihState> {
  final TasbihRepository _repository;
  final _uuid = const Uuid();

  TasbihBloc({required TasbihRepository repository}) 
      : _repository = repository, 
        super(TasbihInitial()) {
    on<LoadTasbihs>(_onLoadTasbihs);
    on<AddTasbih>(_onAddTasbih);
    on<UpdateTasbih>(_onUpdateTasbih);
    on<DeleteTasbih>(_onDeleteTasbih);
  }

  Future<void> _onLoadTasbihs(
    LoadTasbihs event,
    Emitter<TasbihState> emit,
  ) async {
    try {
      emit(TasbihLoading());
      await _repository.init(); // Ensure box is open
      final tasbihs = await _repository.getAllTasbihs();
      emit(TasbihLoaded(tasbihs));
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  Future<void> _onAddTasbih(
    AddTasbih event,
    Emitter<TasbihState> emit,
  ) async {
    try {
      if (state is TasbihLoaded) {
        final currentList = (state as TasbihLoaded).tasbihs;
        final newTasbih = Tasbih(
          id: _uuid.v4(),
          name: event.name,
          targetCount: event.target,
          lastUpdated: DateTime.now(),
        );
        
        await _repository.saveTasbih(newTasbih);
        emit(TasbihLoaded([...currentList, newTasbih]));
      }
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  Future<void> _onUpdateTasbih(
    UpdateTasbih event,
    Emitter<TasbihState> emit,
  ) async {
    try {
      if (state is TasbihLoaded) {
        final currentList = (state as TasbihLoaded).tasbihs;
        await _repository.saveTasbih(event.tasbih);
        
        final updatedList = currentList.map((t) {
          return t.id == event.tasbih.id ? event.tasbih : t;
        }).toList();
        
        emit(TasbihLoaded(updatedList));
      }
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  Future<void> _onDeleteTasbih(
    DeleteTasbih event,
    Emitter<TasbihState> emit,
  ) async {
    try {
      if (state is TasbihLoaded) {
        final currentList = (state as TasbihLoaded).tasbihs;
        await _repository.deleteTasbih(event.id);
        
        final updatedList = currentList.where((t) => t.id != event.id).toList();
        emit(TasbihLoaded(updatedList));
      }
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }
}
