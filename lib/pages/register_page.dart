import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final role = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 50),

            const Text(
              "Criando nova\nconta",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Já está registrado? Login aqui.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "NOME"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "SENHA"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: role,
              decoration: const InputDecoration(labelText: "CARGO/FUNÇÃO"),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/login", arguments: {
                  "name": name.text,
                  "role": role.text,
                });
              },
              child: const Text("Sign up"),
            )
          ],
        ),
      ),
    );
  }
}
