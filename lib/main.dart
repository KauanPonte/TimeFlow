import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_state.dart';
import 'package:flutter_application_appdeponto/repositories/auth_repository.dart';
import 'package:flutter_application_appdeponto/widgets/action_loading_overlay.dart';
import 'pages/splash/splash_page.dart';
import 'services/notification_service.dart';
import 'pages/auth/welcome/welcome_page.dart';
import 'pages/auth/login/login_page.dart';
import 'pages/auth/register/register_page.dart';
import 'pages/auth/forgot_password/forgot_password_page.dart';
import 'pages/home_page/home_page.dart';
import 'pages/admin/home/home_admin_page.dart';
import 'pages/admin/users_management/users_management_page.dart';
import 'pages/ponto_page/ponto_page.dart';
import 'pages/profile_page/profile_page.dart';
import 'pages/history_page/history_page.dart';
// import 'pages/admin/admin_dashboard_page.dart';
// import 'package:flutter_application_appdeponto/blocs/admin/admin_bloc.dart';
// import 'package:flutter_application_appdeponto/repositories/admin_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR');
  await NotificationService.init();
  runApp(const TimeFlow());
}

/// Transição nula — sem animação entre telas.
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
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
        BlocProvider<GlobalLoadingCubit>(
          create: (_) => GlobalLoadingCubit(),
        ),
        // BlocProvider<AdminBloc>(
        //   create: (context) => AdminBloc(
        //     repository: AdminRepository(),
        //   ),
        // ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return BlocBuilder<GlobalLoadingCubit, GlobalLoadingState>(
            builder: (context, loadingState) {
              return ActionLoadingOverlay(
                isProcessing: loadingState.isLoading,
                message: loadingState.message,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoTransitionBuilder(),
              TargetPlatform.iOS: _NoTransitionBuilder(),
              TargetPlatform.windows: _NoTransitionBuilder(),
              TargetPlatform.linux: _NoTransitionBuilder(),
              TargetPlatform.macOS: _NoTransitionBuilder(),
            },
          ),
        ),
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
