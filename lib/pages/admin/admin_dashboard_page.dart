// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'employee_list_page.dart';
// import '../home_page.dart';
// import 'admin_clock_page.dart';

// class AdminDashboardPage extends StatefulWidget {
//   const AdminDashboardPage({super.key});

//   @override
//   State<AdminDashboardPage> createState() => _AdminDashboardPageState();
// }

// class _AdminDashboardPageState extends State<AdminDashboardPage> {
//   // Estado para controlar a direção da seta
//   bool _isGestionOpen = false;

//   @override
//   Widget build(BuildContext context) {
//     initializeDateFormatting('pt_BR', null);

//     return Scaffold(
//       backgroundColor: const Color(0xffF8F9FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         title: Row(
//           children: [
//             const Text(
//               'TimeFlow',
//               style: TextStyle(
//                   color: Color(0xff7B2CBF),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 22),
//             ),
//             const SizedBox(width: 40),
//             _buildTopNav(context),
//           ],
//         ),
//         actions: [
//           IconButton(
//               onPressed: () {},
//               icon:
//                   const Icon(Icons.notifications_none, color: Colors.black54)),
//           IconButton(
//               onPressed: () {},
//               icon: const Icon(Icons.help_outline, color: Colors.black54)),
//           const CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.purple,
//               child: Icon(Icons.person, size: 20, color: Colors.white)),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildWelcomeHeader(),
//                 _buildQuickStats(),
//               ],
//             ),
//             const Text(
//               "Iniciando jornada de hoje",
//               style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 32),
//             Row(
//               children: [
//                 _buildDropdown("Empregador"),
//                 const SizedBox(width: 12),
//                 _buildDropdown("Unidade"),
//               ],
//             ),
//             const SizedBox(height: 32),
//             LayoutBuilder(builder: (context, constraints) {
//               return Wrap(
//                 spacing: 20,
//                 runSpacing: 20,
//                 children: [
//                   _buildInfoCard(
//                       "Horas extras",
//                       "0h 00min",
//                       "Nenhum valor acumulado",
//                       Icons.airplane_ticket_outlined,
//                       constraints.maxWidth,
//                       onTap: () {}),
//                   _buildInfoCard(
//                       "Intervalo",
//                       "0",
//                       "Todos realizaram o intervalo",
//                       Icons.ramen_dining_outlined,
//                       constraints.maxWidth,
//                       onTap: () {}),
//                   _buildInfoCard("Escala", "0", "Nenhuma divergência de escala",
//                       Icons.alarm_on, constraints.maxWidth,
//                       onTap: () {}),
//                 ],
//               );
//             }),
//             const SizedBox(height: 40),
//             // ... dentro da Column do seu body
//             const Text("Ajustes pendentes",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildNavigationTile(
//                     context,
//                     "Registrar Meu Ponto",
//                     Icons.fingerprint,
//                     const AdminPunchClockPage(), // <--- Aqui você chama a nova tela que criamos
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 const Expanded(
//                     child: SizedBox()), // Mantém o alinhamento à esquerda
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- WIDGETS AUXILIARES ---

//   Widget _buildWelcomeHeader() {
//     final now = DateTime.now();
//     final hour = now.hour;
//     String greeting =
//         hour < 12 ? "Bom dia!" : (hour < 18 ? "Boa tarde!" : "Boa noite!");
//     String formattedDate =
//         DateFormat("dd 'de' MMMM 'de' yyyy", "pt_BR").format(now);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(greeting,
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         Text(formattedDate, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildTopNav(BuildContext context) {
//     return Row(
//       children: [
//         _navItemWithMenu(
//           context,
//           "Gestão de ponto",
//           isActive: true,
//           isOpen: _isGestionOpen,
//           options: [
//             {'label': 'Controle de ponto', 'page': const EmployeeListPage()},
//           ],
//         ),
//         _navItem("Relatórios", onTap: () {}),
//         _navItem("Cadastros", onTap: () {}),
//       ],
//     );
//   }

//   Widget _navItemWithMenu(BuildContext context, String label,
//       {bool isActive = false,
//       required bool isOpen,
//       required List<Map<String, dynamic>> options}) {
//     final Color contentColor =
//         isActive ? const Color(0xff7B2CBF) : Colors.black87;

//     return PopupMenuButton<Widget>(
//       offset: const Offset(0, 45),
//       elevation: 4,
//       constraints: const BoxConstraints(minWidth: 180),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: Colors.white,
//       onOpened: () => setState(() => _isGestionOpen = true),
//       onCanceled: () => setState(() => _isGestionOpen = false),
//       onSelected: (Widget? page) {
//         setState(() => _isGestionOpen = false);
//         if (page != null)
//           Navigator.push(context, MaterialPageRoute(builder: (_) => page));
//       },
//       itemBuilder: (context) => options.map((opt) {
//         return PopupMenuItem<Widget>(
//           value: opt['page'] as Widget?,
//           child: Center(
//             child: Text(opt['label'], style: const TextStyle(fontSize: 14)),
//           ),
//         );
//       }).toList(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Row(
//           children: [
//             Text(label,
//                 style: TextStyle(
//                     color: contentColor,
//                     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                     fontSize: 15)),
//             const SizedBox(width: 4),
//             Icon(isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
//                 size: 20, color: contentColor),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _navItem(String label,
//       {bool isActive = false, required VoidCallback onTap}) {
//     final Color contentColor =
//         isActive ? const Color(0xff7B2CBF) : Colors.black87;
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Row(
//           children: [
//             Text(label,
//                 style: TextStyle(
//                     color: contentColor,
//                     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                     fontSize: 15)),
//             const SizedBox(width: 4),
//             const Icon(Icons.keyboard_arrow_up,
//                 size: 20, color: Colors.black87),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String mainValue, String subValue,
//       IconData icon, double width,
//       {required VoidCallback onTap}) {
//     double cardWidth = width > 800 ? (width - 40) / 3 : width;
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           width: cardWidth,
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(color: Colors.grey, fontSize: 14)),
//                   Icon(icon, color: Colors.purple.withOpacity(0.4)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(mainValue,
//                   style: const TextStyle(
//                       fontSize: 28, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Text(subValue,
//                   style: const TextStyle(color: Colors.grey, fontSize: 13)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           Text(label, style: const TextStyle(color: Colors.grey)),
//           const Icon(Icons.arrow_drop_down, color: Colors.grey),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickStats() {
//     return Row(
//       children: [
//         _statItem("0", "atrasados", Colors.teal),
//         const SizedBox(width: 24),
//         _statItem("0", "hora extra", Colors.purple),
//         const SizedBox(width: 24),
//         _statItem("0", "saída antecipada", Colors.redAccent),
//       ],
//     );
//   }

//   Widget _statItem(String value, String label, Color color) {
//     return Column(
//       children: [
//         Text(value,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         Container(
//             height: 2,
//             width: 30,
//             color: color,
//             margin: const EdgeInsets.only(top: 4)),
//       ],
//     );
//   }

//   Widget _buildNavigationTile(
//       BuildContext context, String title, IconData icon, Widget destination) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         onTap: () => Navigator.push(
//             context, MaterialPageRoute(builder: (_) => destination)),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.purple.withOpacity(0.2)),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.purple),
//               const SizedBox(width: 12),
//               Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
