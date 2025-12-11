import 'package:flutter/material.dart';
import 'pages/auth/welcome/welcome_page.dart';
import 'pages/auth/login/login_page.dart';
import 'pages/auth/register/register_page.dart';
import 'pages/home_page.dart';
import 'pages/ponto_page.dart';
import 'pages/profile_page.dart';
import 'pages/history_page.dart';

void main() {
  runApp(const TimeFlow());
}

class TimeFlow extends StatelessWidget {
  const TimeFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        // Rotas com argumentos
        if (settings.name == "/home") {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => HomePage(
              employeeName: args["employeeName"] ?? "",
              profileImageUrl: args["profileImageUrl"] ?? "",
            ),
          );
        }

        return null;
      },
      routes: {
        "/": (context) => const WelcomePage(),
        "/login": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
        "/ponto": (context) => const PontoPage(),
        "/profile": (context) => const ProfilePage(),
        "/history": (context) => const HistoryPage(),
      },
    );
  }
}
