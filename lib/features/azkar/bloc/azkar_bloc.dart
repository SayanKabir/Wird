import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/azkar_repository.dart';
import 'azkar_event_state.dart';

export 'azkar_event_state.dart';

class AzkarBloc extends Bloc<AzkarEvent, AzkarState> {
  final AzkarRepository _repository;

  AzkarBloc({required AzkarRepository repository}) 
      : _repository = repository, 
        super(AzkarInitial()) {
    on<LoadAzkarCategories>(_onLoadCategories);
    on<SelectAzkarCategory>(_onSelectCategory);
  }

  Future<void> _onLoadCategories(
    LoadAzkarCategories event,
    Emitter<AzkarState> emit,
  ) async {
    try {
      emit(AzkarLoading());
      final categories = await _repository.getAvailableCategories();
      emit(AzkarCategoriesLoaded(categories));
    } catch (e) {
      emit(AzkarError(e.toString()));
    }
  }

  Future<void> _onSelectCategory(
    SelectAzkarCategory event,
    Emitter<AzkarState> emit,
  ) async {
    try {
      emit(AzkarLoading());
      final azkars = await _repository.getAzkarByCategory(event.category);
      emit(AzkarListLoaded(category: event.category, azkarList: azkars));
    } catch (e) {
      emit(AzkarError(e.toString()));
    }
  }
}
