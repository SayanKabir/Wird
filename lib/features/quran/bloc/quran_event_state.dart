import 'package:equatable/equatable.dart';
import '../../../models/surah.dart';
import '../../../models/verse.dart';
import '../../../models/quran_bookmark.dart';

// ─────────────────── Events ───────────────────

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

class LoadSurahs extends QuranEvent {}

class OpenSurah extends QuranEvent {
  final int surahId;
  const OpenSurah(this.surahId);

  @override
  List<Object?> get props => [surahId];
}

class CloseSurah extends QuranEvent {}

class SaveBookmark extends QuranEvent {
  final QuranBookmark bookmark;
  const SaveBookmark(this.bookmark);

  @override
  List<Object?> get props => [bookmark];
}

class DeleteBookmark extends QuranEvent {
  final String bookmarkId;
  const DeleteBookmark(this.bookmarkId);

  @override
  List<Object?> get props => [bookmarkId];
}

class UpdateLastRead extends QuranEvent {
  final int surahId;
  final int verseNumber;
  final String? surahName;

  const UpdateLastRead({
    required this.surahId,
    required this.verseNumber,
    this.surahName,
  });

  @override
  List<Object?> get props => [surahId, verseNumber, surahName];
}

// ─────────────────── States ───────────────────

abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object?> get props => [];
}

class QuranInitial extends QuranState {}

class QuranLoading extends QuranState {}

class QuranLoaded extends QuranState {
  final List<Surah> surahs;
  final QuranBookmark? lastRead;
  final List<QuranBookmark> bookmarks;

  const QuranLoaded({
    required this.surahs,
    this.lastRead,
    this.bookmarks = const [],
  });

  @override
  List<Object?> get props => [surahs, lastRead, bookmarks];

  QuranLoaded copyWith({
    List<Surah>? surahs,
    QuranBookmark? lastRead,
    List<QuranBookmark>? bookmarks,
    bool clearLastRead = false,
  }) {
    return QuranLoaded(
      surahs: surahs ?? this.surahs,
      lastRead: clearLastRead ? null : (lastRead ?? this.lastRead),
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

class QuranError extends QuranState {
  final String message;
  const QuranError(this.message);

  @override
  List<Object?> get props => [message];
}

class SurahReading extends QuranState {
  final Surah surah;
  final List<Verse> verses;
  final List<QuranBookmark> bookmarks;
  final bool isLoading;

  const SurahReading({
    required this.surah,
    required this.verses,
    this.bookmarks = const [],
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [surah, verses, bookmarks, isLoading];

  SurahReading copyWith({
    Surah? surah,
    List<Verse>? verses,
    List<QuranBookmark>? bookmarks,
    bool? isLoading,
  }) {
    return SurahReading(
      surah: surah ?? this.surah,
      verses: verses ?? this.verses,
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
