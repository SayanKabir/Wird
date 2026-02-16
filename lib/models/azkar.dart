import 'package:hive/hive.dart';

part 'azkar.g.dart';

@HiveType(typeId: 23)
enum AzkarCategory {
  @HiveField(0)
  morning,
  @HiveField(1)
  evening,
  @HiveField(2)
  beforeSleep,
  @HiveField(3)
  afterPrayer,
  @HiveField(4)
  wakingUp,
  @HiveField(5)
  mosque,
  @HiveField(6)
  wudu,
  @HiveField(7)
  food,
  @HiveField(8)
  home,
  @HiveField(9)
  travel,
  @HiveField(10)
  hajjUmrah,
  @HiveField(11)
  nature,
}

@HiveType(typeId: 24)
class Azkar {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final AzkarCategory category;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final String arabic;

  @HiveField(4)
  final String transliteration;

  @HiveField(5)
  final String translation;

  @HiveField(6)
  final int repetitions;

  @HiveField(7)
  final String virtue; // Benefits or rewards

  @HiveField(8)
  final Map<String, String> reference; // {hadith, book, etc.}

  @HiveField(9)
  final String? audioUrl;
  
  const Azkar({
    required this.id,
    required this.category,
    required this.order,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.repetitions,
    required this.virtue,
    required this.reference,
    this.audioUrl,
  });
}
