import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String nomeFuncionario;

  const ProfilePage({super.key, required this.nomeFuncionario});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  Uint8List? _imageBytes; // <- imagem carregada em memória
  Map<String, dynamic> registros = {};

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadRegistros();
  }

  // ------- CARREGAR PERFIL -------
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nameController.text =
          prefs.getString('user_name') ?? widget.nomeFuncionario;
      roleController.text = prefs.getString('user_role') ?? '';

      final savedImage = prefs.getString('foto_perfil');
      if (savedImage != null && savedImage.isNotEmpty) {
        _imageBytes = base64Decode(savedImage);
      }
    });
  }

  // ------- SALVAR PERFIL -------
  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nameController.text);
    await prefs.setString('user_role', roleController.text);

    if (_imageBytes != null) {
      await prefs.setString('foto_perfil', base64Encode(_imageBytes!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo com sucesso!')),
    );
  }

  // ------- ESCOLHER IMAGEM -------
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _imageBytes = bytes;
        });

        // salva automaticamente ao escolher imagem
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('foto_perfil', base64Encode(bytes));
      } catch (e) {
        debugPrint("Erro ao ler imagem: $e");
      }
    }
  }

  // ------- HISTÓRICO DE PONTO -------
  Future<void> loadRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final String? registrosJson = prefs.getString('registros');
    if (registrosJson != null) {
      setState(() {
        registros = jsonDecode(registrosJson);
      });
    }
  }

  Future<void> limparRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('registros');
    setState(() {
      registros.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registros apagados!')),
    );
  }

  // ------- INTERFACE -------
  @override
  Widget build(BuildContext context) {
    final datas = registros.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // FOTO DE PERFIL
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                backgroundImage:
                    _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                child: _imageBytes == null
                    ? const Icon(Icons.camera_alt,
                        size: 40, color: Colors.grey)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // NOME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // CARGO
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: 'Cargo ou função',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 32),

            // HISTÓRICO DE PONTOS
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Histórico de Pontos",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            registros.isEmpty
                ? const Text("Nenhum registro encontrado.")
                : ListView.builder(
                    itemCount: datas.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = datas[index];
                      final pontos = registros[data];
                      final dataFormatada = DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(data));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📅 $dataFormatada",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (pontos['entrada'] != null)
                                Text("Entrada: ${pontos['entrada']}"),
                              if (pontos['pausa'] != null)
                                Text("Pausa: ${pontos['pausa']}"),
                              if (pontos['retorno'] != null)
                                Text("Retorno: ${pontos['retorno']}"),
                              if (pontos['saida'] != null)
                                Text("Saída: ${pontos['saida']}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: limparRegistros,
              icon: const Icon(Icons.delete_outline, color: Colors.indigo),
              label: const Text(
                "Limpar registros",
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
