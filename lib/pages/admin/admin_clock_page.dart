// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';

// // Simulação dos seus serviços (ajuste os caminhos conforme seu projeto)
// // import '../services/ponto_service.dart';

// class AdminPunchClockPage extends StatefulWidget {
//   const AdminPunchClockPage({super.key});

//   @override
//   State<AdminPunchClockPage> createState() => _AdminPunchClockPageState();
// }

// class _AdminPunchClockPageState extends State<AdminPunchClockPage> {
//   Map<String, Map<String, String>> registros = {};
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('pt_BR', null);
//     _loadRegistros();
//   }

//   // Carrega os dados reais do seu PontoService
//   Future<void> _loadRegistros() async {
//     setState(() => loading = true);
//     // registros = await PontoService.loadRegistros(); // Descomente quando o serviço estiver pronto

//     // Simulação de dados para visualização
//     await Future.delayed(const Duration(milliseconds: 500));
//     registros = {
//       "2024-05-20": {
//         "entrada": "08:00",
//         "pausa": "12:00",
//         "retorno": "13:00",
//         "saida": "17:00"
//       },
//     };

//     setState(() => loading = false);
//   }

//   Future<void> _registrar(String status) async {
//     // Pega o horário atual real do sistema
//     final String tempoAtual = DateFormat("HH:mm").format(DateTime.now());
//     final String dataHoje = DateFormat("yyyy-MM-dd").format(DateTime.now());

//     // Aqui você chamaria o seu serviço real:
//     // await PontoService.registrarPonto(context, status);

//     setState(() {
//       if (!registros.containsKey(dataHoje)) {
//         registros[dataHoje] = {};
//       }
//       registros[dataHoje]![status] = tempoAtual;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Registro de $status realizado às $tempoAtual"),
//         backgroundColor: const Color(0xFF192153),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dates = registros.keys.toList()..sort((a, b) => b.compareTo(a));

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("MEU PONTO (ADMIN)",
//             style: TextStyle(
//                 color: Color(0xFF192153),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: const BackButton(color: Color(0xFF192153)),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           child: Column(
//             children: [
//               const Text(
//                 "PAINEL DE REGISTRO PESSOAL",
//                 style: TextStyle(
//                     fontSize: 12,
//                     letterSpacing: 1.2,
//                     color: Colors.grey,
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),

//               // GRID COLORIDO (Estilo solicitado)
//               GridView.count(
//                 crossAxisCount: 2,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 children: [
//                   _PontoTile(
//                     number: "1",
//                     label: "ENTRADA",
//                     color: const Color(0xFF18A999), // Verde Água
//                     icon: Icons.login,
//                     onTap: () => _registrar("entrada"),
//                   ),
//                   _PontoTile(
//                     number: "2",
//                     label: "PAUSA",
//                     color: const Color(0xFF3DB2FF), // Azul
//                     icon: Icons.coffee,
//                     onTap: () => _registrar("pausa"),
//                   ),
//                   _PontoTile(
//                     number: "3",
//                     label: "RETORNO",
//                     color: const Color(0xFFF7C548), // Amarelo/Laranja
//                     icon: Icons.replay,
//                     onTap: () => _registrar("retorno"),
//                   ),
//                   _PontoTile(
//                     number: "4",
//                     label: "SAÍDA",
//                     color: const Color(0xFFF26464), // Vermelho
//                     icon: Icons.logout,
//                     onTap: () => _registrar("saida"),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 30),
//               const Divider(),
//               const SizedBox(height: 10),
//               const Text(
//                 "HISTÓRICO RECENTE",
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold, color: Color(0xFF192153)),
//               ),
//               const SizedBox(height: 15),

//               // TABELA DE REGISTROS
//               loading
//                   ? const CircularProgressIndicator()
//                   : registros.isEmpty
//                       ? const Text("Nenhum registro encontrado")
//                       : _buildDataTable(dates),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDataTable(List<String> dates) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
//         columnSpacing: 20,
//         columns: const [
//           DataColumn(
//               label:
//                   Text("Data", style: TextStyle(fontWeight: FontWeight.bold))),
//           DataColumn(label: Text("Ent.")),
//           DataColumn(label: Text("Pau.")),
//           DataColumn(label: Text("Ret.")),
//           DataColumn(label: Text("Saí.")),
//         ],
//         rows: dates.map((date) {
//           final map = registros[date] ?? {};
//           return DataRow(
//             cells: [
//               DataCell(Text(DateFormat('dd/MM').format(DateTime.parse(date)))),
//               DataCell(Text(map["entrada"] ?? "-",
//                   style: const TextStyle(color: Color(0xFF18A999)))),
//               DataCell(Text(map["pausa"] ?? "-")),
//               DataCell(Text(map["retorno"] ?? "-")),
//               DataCell(Text(map["saida"] ?? "-",
//                   style: const TextStyle(color: Color(0xFFF26464)))),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _PontoTile extends StatelessWidget {
//   final String number;
//   final String label;
//   final Color color;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _PontoTile({
//     required this.number,
//     required this.label,
//     required this.color,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: color,
//       borderRadius: BorderRadius.circular(15),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(number,
//                       style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white24)),
//                   Icon(icon, color: Colors.white, size: 28),
//                 ],
//               ),
//               const Spacer(),
//               Text(
//                 label,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 5),
//               const Text("Toque para registrar",
//                   style: TextStyle(color: Colors.white70, fontSize: 10)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
