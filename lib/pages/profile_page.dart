import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? imageBytes; // <-- Agora funciona Web + Android + iOS

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final bytes =
          await file.readAsBytes(); // <-- funciona em TODOS plataformas

      setState(() {
        imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final String name = args?["employeeName"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: const Color.fromARGB(255, 251, 251, 252),
        automaticallyImplyLeading: false, // remove a seta
      ),
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ------------------------ FOTO CENTRALIZADA ------------------------
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      imageBytes != null ? MemoryImage(imageBytes!) : null,
                  child: imageBytes == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF192153),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Edite sua foto clicando no ícone acima",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),

      // ------------------------ BOTTOM NAV ------------------------
      bottomNavigationBar: BottomNav(
        index: 2,
        args: args,
      ),
    );
  }
}
