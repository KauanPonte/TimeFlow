// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../blocs/admin/admin_bloc.dart';
// import '../../blocs/admin/admin_event.dart';
// import '../../blocs/admin/admin_state.dart';
// import '../../repositories/admin_repository.dart';

// class EmployeeDetailsPage extends StatelessWidget {
//   final String employeeId;

//   const EmployeeDetailsPage({super.key, required this.employeeId});

//   @override
// Widget build(BuildContext context) {
//   return BlocProvider.value(
//     value: context.read<AdminBloc>()
//       ..add(LoadEmployeeDetails(employeeId)),
//     child: Scaffold(
//       appBar: AppBar(
//         title: const Text('Detalhes do Funcionário'),
//       ),
//       body: BlocBuilder<AdminBloc, AdminState>(
//         builder: (context, state) {
//           if (state is AdminLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           if (state is EmployeeDetailsLoaded) {
//             final e = state.employee;

//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     e['name'] ?? '',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text('Cargo: ${e['role'] ?? ''}'),
//                 ],
//               ),
//             );
//           }

//           if (state is AdminError) {
//             return Center(
//               child: Text(state.message),
//             );
//           }

//           return const SizedBox();
//         },
//       ),
//     ),
//   );
//  }
// }