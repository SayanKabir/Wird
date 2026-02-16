import 'package:hive/hive.dart';

part 'sunnah.g.dart';

@HiveType(typeId: 20)
enum SunnahDifficulty {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  advanced,
}

@HiveType(typeId: 21)
enum SunnahFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  occasional,
}

@HiveType(typeId: 22)
class Sunnah {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final SunnahDifficulty difficulty;

  @HiveField(4)
  final SunnahFrequency frequency;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final String? arabic;

  @HiveField(7)
  final String? transliteration;

  @HiveField(8)
  final String? translation;

  @HiveField(9)
  final String virtue;

  @HiveField(10)
  final Map<String, String> reference; // {hadith, book, etc.}

  @HiveField(11)
  final List<String> tips;

  @HiveField(12)
  final List<String> relatedSunnahs;

  @HiveField(13)
  final String? tasbihId; // links to tasbih preset for dhikr-type sunnahs

  @HiveField(14)
  final int? repetitions; // for counted dhikr (e.g. SubhanAllah 33x)

  const Sunnah({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.frequency,
    required this.description,
    this.arabic,
    this.transliteration,
    this.translation,
    required this.virtue,
    required this.reference,
    this.tips = const [],
    this.relatedSunnahs = const [],
    this.tasbihId,
    this.repetitions,
  });
}
