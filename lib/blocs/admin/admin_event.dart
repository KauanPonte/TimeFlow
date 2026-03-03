import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployees extends AdminEvent {}

class SearchEmployee extends AdminEvent {
  final String query;

  const SearchEmployee(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadEmployeeDetails extends AdminEvent {
  final String employeeId;

  const LoadEmployeeDetails(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}