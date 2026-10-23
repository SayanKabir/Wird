import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/quran_repository.dart';
import 'quran_event_state.dart';

export 'quran_event_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranRepository _repository;

  QuranBloc({required QuranRepository repository})
      : _repository = repository,
        super(QuranInitial()) {
    on<LoadSurahs>(_onLoadSurahs);
    on<SaveBookmark>(_onSaveBookmark);
    on<DeleteBookmark>(_onDeleteBookmark);
    on<UpdateLastRead>(_onUpdateLastRead);
  }

  Future<void> _onLoadSurahs(
    LoadSurahs event,
    Emitter<QuranState> emit,
  ) async {
    try {
      if (state is! QuranLoaded) {
        emit(QuranLoading());
      }

      final surahs = await _repository.getSurahs();
      final lastRead = _repository.getLastRead();
      final bookmarks = _repository.getBookmarks();

      emit(QuranLoaded(
        surahs: surahs,
        lastRead: lastRead,
        bookmarks: bookmarks,
      ));
    } catch (e) {
      emit(QuranError(e.toString()));
    }
  }

  Future<void> _onSaveBookmark(
    SaveBookmark event,
    Emitter<QuranState> emit,
  ) async {
    try {
      await _repository.saveBookmark(event.bookmark);

      final currentState = state;
      if (currentState is QuranLoaded) {
        final bookmarks = _repository.getBookmarks();
        emit(currentState.copyWith(bookmarks: bookmarks));
      }
    } catch (e) {
      // Silently handle bookmark errors
    }
  }

  Future<void> _onDeleteBookmark(
    DeleteBookmark event,
    Emitter<QuranState> emit,
  ) async {
    try {
      await _repository.deleteBookmark(event.bookmarkId);

      final currentState = state;
      if (currentState is QuranLoaded) {
        final bookmarks = _repository.getBookmarks();
        emit(currentState.copyWith(bookmarks: bookmarks));
      }
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> _onUpdateLastRead(
    UpdateLastRead event,
    Emitter<QuranState> emit,
  ) async {
    try {
      await _repository.saveLastRead(
        surahId: event.surahId,
        verseNumber: event.verseNumber,
        surahName: event.surahName,
      );

      final currentState = state;
      if (currentState is QuranLoaded) {
        final lastRead = _repository.getLastRead();
        emit(currentState.copyWith(lastRead: lastRead));
      }
    } catch (e) {
      // Silently handle
    }
  }
}
