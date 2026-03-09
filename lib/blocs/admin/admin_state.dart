// import 'package:equatable/equatable.dart';

// abstract class AdminState extends Equatable {
//   const AdminState();

//   @override
//   List<Object?> get props => [];
// }

// class AdminInitial extends AdminState {}

// class AdminLoading extends AdminState {}

// class EmployeesLoaded extends AdminState {
//   final List<Map<String, dynamic>> employees;

//   const EmployeesLoaded(this.employees);

//   @override
//   List<Object?> get props => [employees];
// }

// class EmployeeDetailsLoaded extends AdminState {
//   final Map<String, dynamic> employee;

//   const EmployeeDetailsLoaded(this.employee);

//   @override
//   List<Object?> get props => [employee];
// }

// class AdminError extends AdminState {
//   final String message;

//   const AdminError(this.message);

//   @override
//   List<Object?> get props => [message];
// }