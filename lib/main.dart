import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';
import 'pages/ponto_page.dart';
import 'pages/profile_page.dart';
import 'pages/history_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa as notificações logo na abertura do app
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const TimeFlow());
}

class TimeFlow extends StatelessWidget {
  const TimeFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      onGenerateRoute: (settings) {
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
        "/login": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
        "/ponto": (context) => const PontoPage(),
        "/profile": (context) => const ProfilePage(),
        "/history": (context) => const HistoryPage(),
      },
    );
  }
}
