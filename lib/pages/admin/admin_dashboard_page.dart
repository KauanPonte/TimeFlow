import 'package:flutter/material.dart';
import 'employee_list_page.dart';
import '../home_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Funcionários'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeeListPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Meu Ponto'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomePage(
                      employeeName: "",
                      profileImageUrl: "",
                      employeeRole: "",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}