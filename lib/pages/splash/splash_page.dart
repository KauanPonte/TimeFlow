import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
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

    final authRepository = context.read<AuthBloc>().authRepository;
    final userData = await authRepository.getUserSession();

    if (!mounted) return;

    if (userData != null) {
      // verify that the stored email still exists in the repository
      final exists =
          await authRepository.validateEmail(userData['email'] ?? '');
      if (exists) {
        // User is still registered — go to home
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {
            'employeeName': userData['name'],
            'profileImageUrl': userData['profileImage'] ?? '',
            'employeeRole': userData['role'],
          },
        );
        return;
      }

      // User no longer exists — clear session and go to welcome
      await authRepository.clearUserSession();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // User not logged in, go to welcome
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
