import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ponto_service.dart';
import '../widgets/bottom_nav.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  final String employeeName;
  final String profileImageUrl;
  final String logoAsset;

  const HomePage({
    super.key,
    this.employeeName = "",
    this.profileImageUrl = "",
    this.logoAsset = 'assets/logo.png',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, Map<String, String>> registros = {};
  double monthBalance = 0.0;
  String employeeName = "";
  String profileImageUrl = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName;
    profileImageUrl = widget.profileImageUrl;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    registros = await PontoService.loadRegistros();
    final prefs = await SharedPreferences.getInstance();
    monthBalance = prefs.getDouble("month_balance") ?? 0.0;

    if (employeeName.isEmpty) {
      employeeName = prefs.getString("employee_name") ?? "";
    }

    if (profileImageUrl.isEmpty) {
      profileImageUrl = prefs.getString("profile_image_path") ?? "";
    }

    setState(() => loading = false);
  }

  Color get balanceColor => monthBalance >= 0 ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    // 🔹 Define a imagem (arquivo salvo OU mascote padrão)
    ImageProvider<Object> imageProvider = profileImageUrl.isNotEmpty
        ? FileImage(File(profileImageUrl)) as ImageProvider
        : const AssetImage('assets/default_mascote.png') as ImageProvider;

    return Scaffold(
      bottomNavigationBar: BottomNav(
        index: 1,
        args: {
          "employeeName": employeeName,
          "profileImageUrl": profileImageUrl,
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ListView(
            children: [
              // linha superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(widget.logoAsset, height: 36, width: 36),
                      const SizedBox(width: 10),
                      const Text("TimeFlow",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.notifications_none, size: 26),
                      SizedBox(width: 12),
                      Icon(Icons.more_vert, size: 28),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                "OLÁ, ${employeeName.toUpperCase()}",
                style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF192153),
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              Center(
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: const Color.fromARGB(255, 193, 255, 255),
                  backgroundImage: imageProvider,
                ),
              ),

              const SizedBox(height: 18),

              const Text("Trabalhando...",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF192153))),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: LinearProgressIndicator(
                  value: 0.45,
                  minHeight: 12,
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  color: const Color(0xFF192153),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 26),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      "/ponto",
                      arguments: {
                        "employeeName": employeeName,
                        "profileImageUrl": profileImageUrl,
                      },
                    );
                  },
                  child: const Text(
                    "BATER PONTO",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text("Meu saldo de horas",
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                        "${monthBalance >= 0 ? '+' : ''}${monthBalance.toStringAsFixed(2)} h",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: balanceColor)),
                    const SizedBox(height: 8),
                    const Text("Horas positivas ou negativas",
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text("Registros recentes",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : registros.isEmpty
                      ? const Text("Nenhum registro ainda.")
                      : Column(
                          children: (() {
                            final datas = registros.keys.toList()
                              ..sort((a, b) => b.compareTo(a));

                            return datas.map((date) {
                              final map = registros[date]!;
                              final texto = map.entries
                                  .map((e) => "${e.key}: ${e.value}")
                                  .join(" • ");

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(date,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(texto)),
                                  ],
                                ),
                              );
                            }).toList();
                          })(),
                        ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
