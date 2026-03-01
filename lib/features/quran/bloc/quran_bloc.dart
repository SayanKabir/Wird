import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/quran_repository.dart';
import '../../../models/surah.dart';
import 'quran_event_state.dart';

export 'quran_event_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranRepository _repository;

  QuranBloc({required QuranRepository repository})
      : _repository = repository,
        super(QuranInitial()) {
    on<LoadSurahs>(_onLoadSurahs);
    on<OpenSurah>(_onOpenSurah);
    on<CloseSurah>(_onCloseSurah);
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

  Future<void> _onOpenSurah(
    OpenSurah event,
    Emitter<QuranState> emit,
  ) async {
    try {
      // Find the surah from loaded state
      final currentState = state;
      List<Surah> surahs = [];
      if (currentState is QuranLoaded) {
        surahs = currentState.surahs;
      }

      Surah? surah;
      for (final s in surahs) {
        if (s.id == event.surahId) {
          surah = s;
          break;
        }
      }
      if (surah == null) {
        throw Exception('Surah not found');
      }

      // Emit loading state for reading
      emit(SurahReading(
        surah: surah,
        verses: [],
        isLoading: true,
      ));

      // Fetch verses
      final verses = await _repository.getVerses(event.surahId);
      final bookmarks = _repository.getBookmarks();

      emit(SurahReading(
        surah: surah,
        verses: verses,
        bookmarks: bookmarks,
        isLoading: false,
      ));
    } catch (e) {
      emit(QuranError(e.toString()));
    }
  }

  Future<void> _onCloseSurah(
    CloseSurah event,
    Emitter<QuranState> emit,
  ) async {
    // Return to loaded state
    add(LoadSurahs());
  }

  Future<void> _onSaveBookmark(
    SaveBookmark event,
    Emitter<QuranState> emit,
  ) async {
    try {
      await _repository.saveBookmark(event.bookmark);

      final currentState = state;
      if (currentState is SurahReading) {
        final bookmarks = _repository.getBookmarks();
        emit(currentState.copyWith(bookmarks: bookmarks));
      } else if (currentState is QuranLoaded) {
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
      if (currentState is SurahReading) {
        final bookmarks = _repository.getBookmarks();
        emit(currentState.copyWith(bookmarks: bookmarks));
      } else if (currentState is QuranLoaded) {
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
