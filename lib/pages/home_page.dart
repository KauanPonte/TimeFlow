import 'package:flutter/material.dart';
import '../widgets/ponto_button.dart';

class HomePage extends StatelessWidget {
  final String nomeFuncionario;
  const HomePage({super.key, required this.nomeFuncionario});

  void registrarPonto(String tipo) {
    debugPrint("Ponto registrado: $tipo");
    // futuramente: mostrar Snackbar, salvar no banco, etc
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> botoes = [
      {"titulo": "Entrada", "icone": Icons.login, "cor": Colors.green},
      {"titulo": "Pausa", "icone": Icons.coffee, "cor": Colors.orange},
      {"titulo": "Retorno", "icone": Icons.refresh, "cor": Colors.blue},
      {"titulo": "Saída", "icone": Icons.logout, "cor": Colors.redAccent},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("App de Ponto"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Olá, $nomeFuncionario 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Escolha o tipo de ponto:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                itemCount: botoes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemBuilder: (context, index) {
                  final item = botoes[index];
                  return PontoButton(
                    titulo: item["titulo"],
                    icone: item["icone"],
                    cor: item["cor"],
                    onPressed: () => registrarPonto(item["titulo"]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
