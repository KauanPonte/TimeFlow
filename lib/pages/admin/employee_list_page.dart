import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../repositories/admin_repository.dart';
import 'employee_details_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  // Variável para armazenar qual período está selecionado
  String _selectedPeriod = "Neste mês";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(
        repository: AdminRepository(),
      )..add(LoadEmployees()),
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FA),
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Controle de ponto",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- CARD DE FILTROS ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Linha de Períodos (Pills)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPill(
                            "Neste mês",
                            active: _selectedPeriod == "Neste mês",
                            onTap: () =>
                                setState(() => _selectedPeriod = "Neste mês"),
                          ),
                          _buildPill(
                            "mês anterior",
                            active: _selectedPeriod == "mês anterior",
                            onTap: () => setState(
                                () => _selectedPeriod = "mês anterior"),
                          ),
                          _buildPill(
                            "Outro",
                            active: _selectedPeriod == "Outro",
                            onTap: () =>
                                setState(() => _selectedPeriod = "Outro"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 3. Barra de Pesquisa
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Pesquise aqui por algum funcionário",
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xffF1F3F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // --- TABELA DE FUNCIONÁRIOS ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is EmployeesLoaded) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 100,
                          horizontalMargin: 24,
                          showCheckboxColumn: false,
                          headingTextStyle: const TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w600),
                          columns: const [
                            DataColumn(label: Text("Nome")),
                            DataColumn(label: Text("Período")),
                            DataColumn(label: Text("Pendências")),
                          ],
                          rows: state.employees.map((employee) {
                            return _buildDataRow(context, employee);
                          }).toList(),
                        ),
                      );
                    }
                    return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()));
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  Widget _buildPill(String label,
      {bool active = false, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        // Adicionado Material para o efeito de clique (splash) aparecer melhor
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              // Cor roxa se estiver ativo, cinza se não estiver
              color: active ? Colors.purple : const Color(0xffF1F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, Map<String, dynamic> employee) {
    return DataRow(
      onSelectChanged: (_) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EmployeeDetailsPage(employeeId: employee['id'])),
        );
      },
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(employee['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(employee['role'] ?? 'Colaborador',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const DataCell(
            Text("01/03/2026 a 31/03/2026", style: TextStyle(fontSize: 13))),
        const DataCell(Icon(Icons.check_circle, color: Colors.green, size: 22)),
      ],
    );
  }
}
