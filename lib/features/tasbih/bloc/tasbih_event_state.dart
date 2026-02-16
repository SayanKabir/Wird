import 'package:equatable/equatable.dart';
import '../../../models/tasbih.dart';

abstract class TasbihEvent extends Equatable {
  const TasbihEvent();

  @override
  List<Object> get props => [];
}

class LoadTasbihs extends TasbihEvent {}

class AddTasbih extends TasbihEvent {
  final String name;
  final int target;
  
  const AddTasbih(this.name, this.target);

  @override
  List<Object> get props => [name, target];
}

class UpdateTasbih extends TasbihEvent {
  final Tasbih tasbih;
  const UpdateTasbih(this.tasbih);

  @override
  List<Object> get props => [tasbih];
}

class DeleteTasbih extends TasbihEvent {
  final String id;
  const DeleteTasbih(this.id);

  @override
  List<Object> get props => [id];
}

abstract class TasbihState extends Equatable {
  const TasbihState();

  @override
  List<Object?> get props => [];
}

class TasbihInitial extends TasbihState {}

class TasbihLoading extends TasbihState {}

class TasbihLoaded extends TasbihState {
  final List<Tasbih> tasbihs;
  
  const TasbihLoaded(this.tasbihs);

  @override
  List<Object> get props => [tasbihs];
}

class TasbihError extends TasbihState {
  final String message;
  const TasbihError(this.message);

  @override
  List<Object> get props => [message];
}
