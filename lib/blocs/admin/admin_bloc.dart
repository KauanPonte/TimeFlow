import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_event.dart';
import 'admin_state.dart';
import '../../repositories/admin_repository.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  // Lista interna para busca
  List<Map<String, dynamic>> _allEmployees = [];

  AdminBloc({required this.repository}) : super(AdminInitial()) {
    on<LoadEmployees>(_onLoadEmployees);
    on<SearchEmployee>(_onSearchEmployee);
    on<LoadEmployeeDetails>(_onLoadEmployeeDetails);
  }

  Future<void> _onLoadEmployees(
      LoadEmployees event, Emitter<AdminState> emit) async {
    emit(AdminLoading());

    try {
      _allEmployees = await repository.getEmployees();
      emit(EmployeesLoaded(_allEmployees));
    } catch (e) {
      emit(AdminError('Erro ao carregar funcionários'));
    }
  }

  void _onSearchEmployee(
      SearchEmployee event, Emitter<AdminState> emit) {
    final query = event.query.toLowerCase();

    final filtered = _allEmployees.where((employee) {
      final name = (employee['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();

    emit(EmployeesLoaded(filtered));
  }

  Future<void> _onLoadEmployeeDetails(
      LoadEmployeeDetails event, Emitter<AdminState> emit) async {
    emit(AdminLoading());

    try {
      final employee = await repository.getEmployeeById(event.employeeId);

      if (employee == null) {
        emit(AdminError('Funcionário não encontrado'));
        return;
      }

      emit(EmployeeDetailsLoaded(employee));
    } catch (e) {
      emit(AdminError('Erro ao carregar detalhes'));
    }
  }
}