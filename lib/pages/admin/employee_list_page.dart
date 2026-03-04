import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../repositories/admin_repository.dart';
import 'employee_details_page.dart';

class EmployeeListPage extends StatelessWidget {
  const EmployeeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(
        repository: AdminRepository(),
      )..add(LoadEmployees()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Funcionários')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pesquise aqui por funcionário',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  context.read<AdminBloc>().add(SearchEmployee(value));
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is EmployeesLoaded) {
                    return ListView.builder(
                      itemCount: state.employees.length,
                      itemBuilder: (context, index) {
                        final employee = state.employees[index];

                        return ListTile(
                          title: Text(employee['name'] ?? ''),
                          subtitle:
                              Text('Cargo: ${employee['role'] ?? ''}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetailsPage(
                                  employeeId: employee['id'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}