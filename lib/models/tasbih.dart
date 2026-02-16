import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'tasbih.g.dart';

@HiveType(typeId: 25)
class Tasbih extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int currentCount;

  @HiveField(3)
  final int targetCount;

  @HiveField(4)
  final int totalCount; // Lifetime count

  @HiveField(5)
  final DateTime lastUpdated;

  const Tasbih({
    required this.id,
    required this.name,
    this.currentCount = 0,
    this.targetCount = 33,
    this.totalCount = 0,
    required this.lastUpdated,
  });

  Tasbih copyWith({
    String? id,
    String? name,
    int? currentCount,
    int? targetCount,
    int? totalCount,
    DateTime? lastUpdated,
  }) {
    return Tasbih(
      id: id ?? this.id,
      name: name ?? this.name,
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [id, name, currentCount, targetCount, totalCount, lastUpdated];
}
