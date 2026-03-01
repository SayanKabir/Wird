import 'package:hive/hive.dart';

part 'quran_bookmark.g.dart';

@HiveType(typeId: 32)
class QuranBookmark extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int surahId;

  @HiveField(2)
  final int verseNumber;

  @HiveField(3)
  final String? surahName;

  @HiveField(4)
  final String? label;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isLastRead;

  QuranBookmark({
    required this.id,
    required this.surahId,
    required this.verseNumber,
    this.surahName,
    this.label,
    this.note,
    required this.createdAt,
    this.isLastRead = false,
  });

  QuranBookmark copyWith({
    String? id,
    int? surahId,
    int? verseNumber,
    String? surahName,
    String? label,
    String? note,
    DateTime? createdAt,
    bool? isLastRead,
  }) {
    return QuranBookmark(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      verseNumber: verseNumber ?? this.verseNumber,
      surahName: surahName ?? this.surahName,
      label: label ?? this.label,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isLastRead: isLastRead ?? this.isLastRead,
    );
  }
}
