// lib/pages/ponto_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../services/ponto_service.dart';
import '../services/notification_service.dart';

class PontoPage extends StatefulWidget {
  const PontoPage({super.key});

  @override
  State<PontoPage> createState() => _PontoPageState();
}

class _PontoPageState extends State<PontoPage> {
  Map<String, Map<String, String>> registros = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();

    // Notificação diária (SEM criar instância)
    NotificationService.scheduleDailyNotification(
      title: "Bom dia! ☀️",
      body: "Mais um day office! Já bateu seu ponto hoje?",
      hour: 9,
      minute: 0,
    );

    _initSistema();
  }

  Future<void> _initSistema() async {
    await _loadRegistros();
    await _checkPontoDoDia();
  }

  Future<void> _loadRegistros() async {
    setState(() => loading = true);
    registros = await PontoService.loadRegistros();
    setState(() => loading = false);
  }

  Future<void> _registrar(String status) async {
    await PontoService.registrarPonto(context, status);
    await _loadRegistros();

    switch (status) {
      case "entrada":
        NotificationService.showInstantNotification(
          title: "Ponto registrado",
          body: "Bom trabalho! Sua entrada foi registrada.",
        );
        break;
      case "pausa":
        NotificationService.showInstantNotification(
          title: "Pausa iniciada",
          body: "Lembre-se de registrar o retorno depois.",
        );
        break;
      case "retorno":
        NotificationService.showInstantNotification(
          title: "Retorno registrado",
          body: "Continue com foco no seu trabalho!",
        );
        break;
      case "saida":
        NotificationService.showInstantNotification(
          title: "Saída registrada",
          body: "Bom descanso! Até amanhã.",
        );
        break;
    }
  }

  Future<void> _checkPontoDoDia() async {
    final hoje = DateTime.now();
    final data = "${hoje.year}-${hoje.month}-${hoje.day}";

    if (!registros.containsKey(data)) {
      NotificationService.showInstantNotification(
        title: "Atenção!",
        body: "Vimos que você ainda não bateu o ponto hoje.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = registros.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      bottomNavigationBar: BottomNav(
        index: 0,
        args: ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>?,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const Text(
                "STATUS DE TRABALHO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF192153),
                ),
              ),
              const SizedBox(height: 20),

              // GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _PontoTile(
                    number: "1",
                    label: "entrada",
                    color: const Color(0xFF18A999),
                    icon: Icons.login,
                    onTap: () => _registrar("entrada"),
                  ),
                  _PontoTile(
                    number: "2",
                    label: "pausa",
                    color: const Color(0xFF3DB2FF),
                    icon: Icons.coffee,
                    onTap: () => _registrar("pausa"),
                  ),
                  _PontoTile(
                    number: "3",
                    label: "retorno",
                    color: const Color(0xFFF7C548),
                    icon: Icons.replay,
                    onTap: () => _registrar("retorno"),
                  ),
                  _PontoTile(
                    number: "4",
                    label: "saída",
                    color: const Color(0xFFF26464),
                    icon: Icons.logout,
                    onTap: () => _registrar("saida"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TABELA
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : registros.isEmpty
                      ? const Text("Nenhum registro ainda")
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.shade200,
                            ),
                            columns: const [
                              DataColumn(label: Text("Data")),
                              DataColumn(label: Text("Entrada")),
                              DataColumn(label: Text("Pausa")),
                              DataColumn(label: Text("Retorno")),
                              DataColumn(label: Text("Saída")),
                            ],
                            rows: dates.map((date) {
                              final map = registros[date] ?? {};
                              return DataRow(
                                cells: [
                                  DataCell(Text(date)),
                                  DataCell(Text(map["entrada"] ?? "-")),
                                  DataCell(Text(map["pausa"] ?? "-")),
                                  DataCell(Text(map["retorno"] ?? "-")),
                                  DataCell(Text(map["saida"] ?? "-")),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PontoTile extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PontoTile({
    required this.number,
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, color: Colors.white, size: 38),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
