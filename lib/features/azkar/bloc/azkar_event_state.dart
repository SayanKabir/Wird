import 'package:equatable/equatable.dart';
import '../../../models/azkar.dart';

abstract class AzkarEvent extends Equatable {
  const AzkarEvent();

  @override
  List<Object> get props => [];
}

class LoadAzkarCategories extends AzkarEvent {}

class SelectAzkarCategory extends AzkarEvent {
  final AzkarCategory category;
  const SelectAzkarCategory(this.category);

  @override
  List<Object> get props => [category];
}

abstract class AzkarState extends Equatable {
  const AzkarState();

  @override
  List<Object?> get props => [];
}

class AzkarInitial extends AzkarState {}

class AzkarLoading extends AzkarState {}

class AzkarCategoriesLoaded extends AzkarState {
  final List<AzkarCategory> categories;
  const AzkarCategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class AzkarListLoaded extends AzkarState {
  final AzkarCategory category;
  final List<Azkar> azkarList;
  
  const AzkarListLoaded({
    required this.category,
    required this.azkarList,
  });

  @override
  List<Object> get props => [category, azkarList];
}

class AzkarError extends AzkarState {
  final String message;
  const AzkarError(this.message);

  @override
  List<Object> get props => [message];
}
