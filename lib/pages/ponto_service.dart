import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PontoPage extends StatefulWidget {
  @override
  State<PontoPage> createState() => _PontoPageState();
}

class _PontoPageState extends State<PontoPage> {
  Future<void> registrarPonto(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final String hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String horaAtual = DateFormat('HH:mm').format(DateTime.now());

    Map<String, dynamic> registros = {};
    final registrosJson = prefs.getString('registros');

    if (registrosJson != null) {
      registros = jsonDecode(registrosJson);
    }

    registros[hoje] ??= {};
    registros[hoje][status] = horaAtual;

    await prefs.setString('registros', jsonEncode(registros));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ponto de $status registrado às $horaAtual")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Ponto")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => registrarPonto('entrada'),
              child: const Text("Registrar Entrada"),
            ),
            ElevatedButton(
              onPressed: () => registrarPonto('pausa'),
              child: const Text("Registrar Pausa"),
            ),
            ElevatedButton(
              onPressed: () => registrarPonto('retorno'),
              child: const Text("Registrar Retorno"),
            ),
            ElevatedButton(
              onPressed: () => registrarPonto('saida'),
              child: const Text("Registrar Saída"),
            ),
          ],
        ),
      ),
    );
  }
}
