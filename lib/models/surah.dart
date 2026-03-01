import 'package:hive/hive.dart';

part 'surah.g.dart';

@HiveType(typeId: 30)
class Surah extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String nameArabic;

  @HiveField(2)
  final String nameTranslation;

  @HiveField(3)
  final String nameTransliteration;

  @HiveField(4)
  final int versesCount;

  @HiveField(5)
  final String revelationPlace; // 'makkah' or 'madinah'

  @HiveField(6)
  final int revelationOrder;

  @HiveField(7)
  final List<int> pages;

  Surah({
    required this.id,
    required this.nameArabic,
    required this.nameTranslation,
    required this.nameTransliteration,
    required this.versesCount,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.pages,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String? ?? '',
      nameTranslation: json['translated_name']?['name'] as String? ?? '',
      nameTransliteration: json['name_simple'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      revelationOrder: json['revelation_order'] as int? ?? 0,
      pages: (json['pages'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }
}
