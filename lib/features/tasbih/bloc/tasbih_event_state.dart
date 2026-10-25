import 'package:equatable/equatable.dart';
import '../../../models/tasbih.dart';

abstract class TasbihEvent extends Equatable {
  const TasbihEvent();

  @override
  List<Object> get props => [];
}

class LoadTasbihs extends TasbihEvent {}

/// Base for events that act on one counter.
abstract class _CounterEvent extends TasbihEvent {
  final String id;
  const _CounterEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CounterTapped extends _CounterEvent {
  const CounterTapped(super.id);
}

class CounterUndone extends _CounterEvent {
  const CounterUndone(super.id);
}

class CounterReset extends _CounterEvent {
  const CounterReset(super.id);
}

class DeleteTasbih extends _CounterEvent {
  const DeleteTasbih(super.id);
}

/// A tap (or undo, with a negative [delta]) inside a session, credited to the
/// matching counter's totals without touching its round.
class CounterTallied extends TasbihEvent {
  final String id;
  final int delta;
  const CounterTallied(this.id, this.delta);

  @override
  List<Object> get props => [id, delta];
}

class AddTasbih extends TasbihEvent {
  final String name;
  final int target;

  const AddTasbih(this.name, this.target);

  @override
  List<Object> get props => [name, target];
}

class EditTasbih extends TasbihEvent {
  final String id;
  final String name;
  final int target;

  const EditTasbih(this.id, this.name, this.target);

  @override
  List<Object> get props => [id, name, target];
}

abstract class TasbihState extends Equatable {
  const TasbihState();

  @override
  List<Object?> get props => [];
}

class TasbihInitial extends TasbihState {}

class TasbihLoading extends TasbihState {}

class TasbihLoaded extends TasbihState {
  /// Every stored counter, retired ones included (for lifetime totals).
  final List<Tasbih> tasbihs;

  const TasbihLoaded(this.tasbihs);

  Tasbih? byId(String id) {
    for (final t in tasbihs) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  List<Object> get props => [tasbihs];
}

class TasbihError extends TasbihState {
  final String message;
  const TasbihError(this.message);

  @override
  List<Object> get props => [message];
}
