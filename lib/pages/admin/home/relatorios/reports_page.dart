import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'User_Reports_Page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final List<String> allUsers = [
    "Fulaninho da Silva",
  ];
  List<String> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = allUsers; // Inicialmente, mostra todos
  }

  void _runFilter(String enteredKeyword) {
    List<String> results = [];
    if (enteredKeyword.isEmpty) {
      results = allUsers;
    } else {
      results = allUsers
          .where((user) =>
              user.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredUsers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Usuário', style: AppTextStyles.h3),
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Pesquisar',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
          // LISTA FILTRADA
          Expanded(
            child: ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: Text(filteredUsers[index],
                      style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserReportsPage(userName: filteredUsers[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
