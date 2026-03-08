import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/repositories/auth_repository.dart';
import 'pages/splash/splash_page.dart';
import 'pages/auth/welcome/welcome_page.dart';
import 'pages/auth/login/login_page.dart';
import 'pages/auth/register/register_page.dart';
import 'pages/auth/forgot_password/forgot_password_page.dart';
import 'pages/home_page/home_page.dart';
import 'pages/admin/home/home_admin_page.dart';
import 'pages/admin/users_management/users_management_page.dart';
import 'pages/ponto_page.dart';
import 'pages/profile_page/profile_page.dart';
import 'pages/history_page.dart';
// import 'pages/admin/admin_dashboard_page.dart';
// import 'package:flutter_application_appdeponto/blocs/admin/admin_bloc.dart';
// import 'package:flutter_application_appdeponto/repositories/admin_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TimeFlow());
}

class TimeFlow extends StatelessWidget {
  const TimeFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(),
          ),
        ),
        // BlocProvider<AdminBloc>(
        //   create: (context) => AdminBloc(
        //     repository: AdminRepository(),
        //   ),
        // ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: "/",
        onGenerateRoute: (settings) {
          if (settings.name == "/home") {
            final args = settings.arguments as Map<String, dynamic>;
            final employeeRole = args["employeeRole"] ?? "";

            // Redireciona para home admin se o cargo contém "ADM"
            if (employeeRole.toUpperCase().contains("ADM")) {
              return MaterialPageRoute(
                builder: (context) => HomeAdminPage(
                  employeeName: args["employeeName"] ?? "",
                  profileImageUrl: args["profileImageUrl"] ?? "",
                  employeeRole: employeeRole,
                ),
              );
            }

            return MaterialPageRoute(
              builder: (context) => HomePage(
                employeeName: args["employeeName"] ?? "",
                profileImageUrl: args["profileImageUrl"] ?? "",
                employeeRole: args["employeeRole"] ?? "",
              ),
            );
          }

          // Rota exclusiva para admin acessar a home de funcionário (aba Meu Ponto)
          if (settings.name == "/home/employee") {
            final args = (settings.arguments as Map<String, dynamic>?) ?? {};
            return MaterialPageRoute(
              builder: (context) => HomePage(
                employeeName: args["employeeName"] ?? "",
                profileImageUrl: args["profileImageUrl"] ?? "",
                employeeRole: args["employeeRole"] ?? "",
              ),
            );
          }

          // if (settings.name == "/admin") {
          //   return MaterialPageRoute(
          //     builder: (context) => const AdminDashboardPage(),
          //   );
          // }

          return null;
        },
        routes: {
          "/": (context) => const SplashPage(),
          "/welcome": (context) => const WelcomePage(),
          "/login": (context) => const LoginPage(),
          "/register": (context) => const RegisterPage(),
          "/forgot-password": (context) => const ForgotPasswordPage(),
          "/ponto": (context) => const PontoPage(),
          "/profile": (context) => const ProfilePage(),
          "/history": (context) => const HistoryPage(),
          "/admin/users": (context) => const UsersManagementPage(),
        },
      ),
    );
  }
}
