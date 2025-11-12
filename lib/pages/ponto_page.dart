import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PontoPage extends StatefulWidget {
  const PontoPage({Key? key}) : super(key: key);

  @override
  State<PontoPage> createState() => _PontoPageState();
}

class _PontoPageState extends State<PontoPage> {
  Map<String, String> registros = {
    "Entrada": "Nenhum registro",
    "Pausa": "Nenhum registro",
    "Retorno": "Nenhum registro",
    "Saída": "Nenhum registro",
  };

  @override
  void initState() {
    super.initState();
    carregarRegistros();
  }

  Future<void> carregarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      registros = {
        "Entrada": prefs.getString('Entrada') ?? "Nenhum registro",
        "Pausa": prefs.getString('Pausa') ?? "Nenhum registro",
        "Retorno": prefs.getString('Retorno') ?? "Nenhum registro",
        "Saída": prefs.getString('Saída') ?? "Nenhum registro",
      };
    });
  }

  Future<void> registrar(String tipo) async {
    final agora = DateTime.now();
    final hora = DateFormat('HH:mm').format(agora);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tipo, hora);

    setState(() {
      registros[tipo] = hora;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo registrada às $hora'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget buildCard({
    required int numero,
    required String texto,
    required IconData icone,
    required Color cor,
  }) {
    return GestureDetector(
      onTap: () => registrar(texto),
      child: Container(
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Número no canto superior esquerdo
            Positioned(
              top: 8,
              left: 12,
              child: Text(
                numero.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Conteúdo centralizado
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, color: Colors.white, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    texto.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void limparRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      registros.updateAll((key, value) => "Nenhum registro");
    });
  }

  @override
  Widget build(BuildContext context) {
    final horaAtual = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Status de Trabalho",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              horaAtual,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),

            // Grade 2x2 com blocos coloridos
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  buildCard(
                    numero: 1,
                    texto: "Entrada",
                    icone: Icons.login_rounded,
                    cor: const Color(0xFF4CB5AE), // Verde água
                  ),
                  buildCard(
                    numero: 2,
                    texto: "Pausa",
                    icone: Icons.free_breakfast_rounded,
                    cor: const Color(0xFF5E9EDA), // Azul claro
                  ),
                  buildCard(
                    numero: 3,
                    texto: "Retorno",
                    icone: Icons.local_cafe_rounded,
                    cor: const Color(0xFFF4B860), // Amarelo
                  ),
                  buildCard(
                    numero: 4,
                    texto: "Saída",
                    icone: Icons.logout_rounded,
                    cor: const Color(0xFFF17C67), // Vermelho alaranjado
                  ),
                ],
              ),
            ),

            // Botão de limpar registros
            ElevatedButton.icon(
              onPressed: limparRegistros,
              icon: const Icon(Icons.delete_outline),
              label: const Text("Limpar registros"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[50],
                foregroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
