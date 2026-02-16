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

class MarkSunnahPracticed extends SunnahEvent {
  final String sunnahId;

  const MarkSunnahPracticed({required this.sunnahId});

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

  const SunnahLoaded({
    required this.sunnahs,
    this.weeklySunnah,
    required this.progress,
  });

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
  List<Object> get props => [sunnahs, weeklySunnah ?? '', progress];
}

class SunnahError extends SunnahState {
  final String message;

  const SunnahError(this.message);

  @override
  List<Object> get props => [message];
}
