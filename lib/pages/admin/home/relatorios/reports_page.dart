import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'user_reports_page.dart';
import 'package:flutter_application_appdeponto/repositories/admin_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AdminRepository _adminRepo = AdminRepository();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final employees = await _adminRepo.getEmployees();
      final admins = await _adminRepo.getAdmins();

      setState(() {
        allUsers = [...employees, ...admins];
        filteredUsers = allUsers;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar usuários: $e");
      setState(() => isLoading = false);
    }
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      if (enteredKeyword.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers
            .where((user) => (user['nome'] ?? user['name'] ?? "")
                .toLowerCase()
                .contains(enteredKeyword.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Fundo leve para a lista
      appBar: AppBar(
        title: Text(
          'Selecionar Usuário',
          style: AppTextStyles.h3
              .copyWith(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(color: AppColors.primary), // Botão Azul
      ),
      body: Column(
        children: [
          // BACKGROUND AZUL ATRÁS DA PESQUISA
          Stack(
            children: [
              Container(
                height: 45, // Altura do detalhe azul
                decoration: const BoxDecoration(
                  //color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
              // BARRA DE PESQUISA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: TextField(
                  onChanged: (value) => _runFilter(value),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar',
                    hintStyle:
                        AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),

          // LISTA FILTRADA
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? const Center(child: Text("Nenhum usuário encontrado."))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final String name =
                              user['nome'] ?? user['name'] ?? "Usuário";
                          final String? photo = user['profileImageURL'];

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary
                                    .withOpacity(0.1), // Tom de azul
                                backgroundImage:
                                    photo != null ? NetworkImage(photo) : null,
                                child: photo == null
                                    ? const Icon(Icons.person,
                                        color: AppColors.primary)
                                    : null,
                              ),
                              title: Text(name,
                                  style: AppTextStyles.bodyLarge
                                      .copyWith(fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserReportsPage(
                                        userName: name,
                                        profileImageUrl: photo,
                                        userId: user['id'],
                                        jornadaFixa: user['workloadMinutes'] ??
                                            8), //precisa colocar aqui também a role, na verdade só retorna se for dev. Desabilitar
                                  ),
                                );
                              },
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
