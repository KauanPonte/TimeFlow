import 'package:equatable/equatable.dart';

class GlobalLoadingState extends Equatable {
  final bool isLoading;
  final String message;

  const GlobalLoadingState({
    this.isLoading = false,
    this.message = '',
  });

  @override
  List<Object?> get props => [isLoading, message];
}
