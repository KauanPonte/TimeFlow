import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Dispatch event to check authentication status via BLoC
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AdminAuthenticated) {
          // Carrega dados de ponto cedo para popular notificações na AppBar.
          context.read<PontoTodayCubit>().load();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin',
            (route) => false,
            arguments: {
              'employeeName': state.userData['name'],
              'profileImageUrl': state.userData['profileImage'] ?? '',
              'employeeRole': state.userData['role'],
            },
          );
        } else if (state is UserAuthenticated) {
          // Carrega dados de ponto cedo para popular notificações na AppBar.
          context.read<PontoTodayCubit>().load();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
            arguments: {
              'employeeName': state.userData['name'],
              'profileImageUrl': state.userData['profileImage'] ?? '',
              'employeeRole': state.userData['role'],
            },
          );
        } else if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
