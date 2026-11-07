import 'package:equatable/equatable.dart';
import '../../../models/sunnah.dart';
import '../../../models/sunnah_progress.dart';

abstract class SunnahEvent extends Equatable {
  const SunnahEvent();

  @override
  List<Object> get props => [];
}

class LoadSunnahs extends SunnahEvent {}

class SkipWeeklySunnah extends SunnahEvent {}

/// Marks a sunnah as done today, or undoes it if it already is.
class ToggleSunnahToday extends SunnahEvent {
  final String sunnahId;

  const ToggleSunnahToday(this.sunnahId);

  @override
  List<Object> get props => [sunnahId];
}

/// Marks the Sunnahs a finished dhikr keeps as done today. Ones outside the
/// practice, or already done, are left alone.
class MarkPracticeDone extends SunnahEvent {
  final List<String> sunnahIds;

  const MarkPracticeDone(this.sunnahIds);

  @override
  List<Object> get props => [sunnahIds];
}

/// Adds a sunnah to the user's practice, or removes it.
class ToggleSunnahPractice extends SunnahEvent {
  final String sunnahId;

  const ToggleSunnahPractice(this.sunnahId);

  @override
  List<Object> get props => [sunnahId];
}

abstract class SunnahState extends Equatable {
  const SunnahState();

  @override
  List<Object> get props => [];
}

class SunnahLoading extends SunnahState {}

class SunnahLoaded extends SunnahState {
  final List<Sunnah> sunnahs;
  final Sunnah? weeklySunnah;
  final SunnahProgress progress;

  /// Sunnahs added to the practice by default on this load, so the dhikr
  /// page can give the dhikr among them a counter. Empty after the first run.
  final List<String> seeded;

  const SunnahLoaded({
    required this.sunnahs,
    this.weeklySunnah,
    required this.progress,
    this.seeded = const [],
  });

  /// The user's practice, in the order they added it.
  List<Sunnah> get practice {
    final byId = {for (final s in sunnahs) s.id: s};
    return [
      for (final id in progress.practiceIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  SunnahLoaded copyWith({
    List<Sunnah>? sunnahs,
    Sunnah? weeklySunnah,
    SunnahProgress? progress,
  }) {
    return SunnahLoaded(
      sunnahs: sunnahs ?? this.sunnahs,
      weeklySunnah: weeklySunnah ?? this.weeklySunnah,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object> get props => [sunnahs, weeklySunnah ?? '', progress, seeded];
}

class SunnahError extends SunnahState {
  final String message;

  const SunnahError(this.message);

  @override
  List<Object> get props => [message];
}
