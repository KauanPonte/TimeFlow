import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final picker = ImagePicker();
  File? selectedImage;

  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("Criar Conta",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Foto escolhida
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        selectedImage != null ? FileImage(selectedImage!) : null,
                    child: selectedImage == null
                        ? const Icon(Icons.camera_alt, size: 32)
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nome completo"),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: "Cargo"),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Senha"),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      "/home",
                      arguments: {
                        "employeeName": nameController.text,
                        "profileImageUrl": selectedImage?.path ?? "",
                        "employeeRole": roleController.text,
                      },
                    );
                  },
                  child: const Text("Criar Conta"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
