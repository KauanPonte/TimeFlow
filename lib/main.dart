import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_appdeponto/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_state.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/repositories/atestado_repository.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_bloc.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'package:flutter_application_appdeponto/repositories/auth_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/repositories/profile_repository.dart';
import 'package:flutter_application_appdeponto/repositories/solicitation_repository.dart';
import 'package:flutter_application_appdeponto/widgets/action_loading_overlay.dart';
import 'package:flutter_application_appdeponto/widgets/connectivity_guard.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/theme_controller.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Persistência local explícita + cache ilimitado. Garante que os streams
  // sempre emitam do disco primeiro (sem spinner na reabertura) e que meses
  // antigos não sejam despejados do cache. Deve ser definido antes de
  // qualquer operação Firestore (inclusive disableNetwork abaixo).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Verifica transporte de rede de forma instantânea antes de qualquer
  // operação Firestore. Se offline, desabilita a rede do SDK para impedir
  // tentativas de reconexão (WriteStream) e os erros de DNS associados.
  final connectivityResult = await Connectivity().checkConnectivity();
  final hasTransport = connectivityResult != ConnectivityResult.none;
  if (hasTransport) {
    await ServerTimeService.sync();
  } else {
    await FirebaseFirestore.instance.disableNetwork();
  }
  await HistoryViewPreferenceRepository.initialize();
  await AppThemeController.initialize();
  await initializeDateFormatting('pt_BR');
  await NotificationService.init();
  try {
    await NotificationService.scheduleForLastLoggedUser();
  } catch (_) {}
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
        BlocProvider<PontoDataChangedCubit>(
          create: (_) => PontoDataChangedCubit(),
        ),
        BlocProvider<PontoTodayCubit>(
          create: (context) => PontoTodayCubit(
            dataChangedCubit: context.read<PontoDataChangedCubit>(),
          ),
        ),
        BlocProvider<PontoHistoryBloc>(
          create: (context) => PontoHistoryBloc(
            repository: PontoHistoryRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
            dataChangedCubit: context.read<PontoDataChangedCubit>(),
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            profileRepository: ProfileRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
          ),
        ),
        BlocProvider<AdminHomeBloc>(
          create: (_) => AdminHomeBloc(),
        ),
        BlocProvider<SolicitationBloc>(
          create: (context) => SolicitationBloc(
            repository: SolicitationRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
          ),
        ),
        BlocProvider<AtestadoBloc>(
          create: (context) => AtestadoBloc(
            repository: AtestadoRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
          ),
        ),
        BlocProvider<JustificativaBloc>(
          create: (context) => JustificativaBloc(
            repository: JustificativaRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
          ),
        ),
        BlocProvider<AbonoBloc>(
          create: (context) => AbonoBloc(
            repository: AbonoRepository(),
            globalLoading: context.read<GlobalLoadingCubit>(),
          ),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.mode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Seu App',
            debugShowCheckedModeBanner: false,
            // Adicione estas linhas:
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'), // Português Brasil
            ],
            builder: (context, child) {
              final appShell = BlocListener<AuthBloc, AuthState>(
                // Logout: limpa todos os dados ao sair de qualquer conta
                listenWhen: (previous, current) =>
                    (previous is UserAuthenticated ||
                        previous is AdminAuthenticated) &&
                    current is AuthFieldsState,
                listener: (context, _) {
                  context.read<PontoTodayCubit>().clear();
                  context.read<PontoHistoryBloc>().reset();
                  context.read<ProfileBloc>().reset();
                  context.read<AdminHomeBloc>().reset();
                  context.read<SolicitationBloc>().reset();
                  context.read<AtestadoBloc>().reset();
                  context.read<JustificativaBloc>().reset();
                  HistoryViewPreferenceRepository.clearCache();
                },
                child: BlocListener<AuthBloc, AuthState>(
                  // Login direto (ex: tela de login, sem passar pelo splash):
                  // garante que as notificações sejam carregadas mesmo nesse caminho.
                  listenWhen: (previous, current) =>
                      (current is UserAuthenticated ||
                          current is AdminAuthenticated) &&
                      previous is! UserAuthenticated &&
                      previous is! AdminAuthenticated,
                  listener: (context, state) {
                    // Só dispara se o bloc ainda não tem dados (splash já cuida do caso normal)
                    final solState = context.read<SolicitationBloc>().state;
                    bool isAdmin = state is AdminAuthenticated;
                    if (!isAdmin && state is UserAuthenticated) {
                      final r = (state.userData['role'] ?? '').toString();
                      isAdmin = r.toUpperCase().contains('ADM');
                    }
                    if (solState is! SolicitationLoaded &&
                        solState is! SolicitationLoading) {
                      context
                          .read<SolicitationBloc>()
                          .add(LoadSolicitationsEvent(isAdmin: isAdmin));
                    }
                    // Carrega atestados para funcionários (para notificações de resultado)
                    if (!isAdmin) {
                      final atestadoState = context.read<AtestadoBloc>().state;
                      if (atestadoState is! AtestadoLoaded &&
                          atestadoState is! AtestadoLoading) {
                        context
                            .read<AtestadoBloc>()
                            .add(const LoadAtestadosEvent(isAdmin: false));
                      }
                      final justState = context.read<JustificativaBloc>().state;
                      if (justState is! JustificativaLoaded &&
                          justState is! JustificativaLoading) {
                        context
                            .read<JustificativaBloc>()
                            .add(const LoadJustificativasEvent(isAdmin: false));
                      }
                    }
                  },
                  child: BlocBuilder<GlobalLoadingCubit, GlobalLoadingState>(
                    builder: (context, loadingState) {
                      return ActionLoadingOverlay(
                        isProcessing: loadingState.isLoading,
                        message: loadingState.message,
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              );

              return ConnectivityGuard(child: appShell);
            },
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeMode,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
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
                    initialHistoryDate: args["initialHistoryDate"] as String?,
                  ),
                );
              }

              // Rota exclusiva para admin acessar a home de funcionário (aba Meu Ponto)
              if (settings.name == "/home/employee") {
                final args =
                    (settings.arguments as Map<String, dynamic>?) ?? {};
                return MaterialPageRoute(
                  builder: (context) => HomePage(
                    employeeName: args["employeeName"] ?? "",
                    profileImageUrl: args["profileImageUrl"] ?? "",
                    employeeRole: args["employeeRole"] ?? "",
                    initialHistoryDate: args["initialHistoryDate"] as String?,
                  ),
                );
              }

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
          );
        },
      ),
    );
  }
}

ThemeData _buildLightTheme() {
  return ThemeData.light().copyWith(
    pageTransitionsTheme: _pageTransitionsTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    canvasColor: AppColors.surface,
    cardColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      actionsIconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
    splashColor: AppColors.primaryLight.withAlpha(31),
    highlightColor: AppColors.primaryLight.withAlpha(20),
    focusColor: AppColors.primaryLight.withAlpha(20),
    elevatedButtonTheme: _elevatedButtonTheme,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    timePickerTheme: _timePickerTheme(Brightness.light),
    datePickerTheme: _datePickerTheme(Brightness.light),
    inputDecorationTheme: _inputDecorationTheme,
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData.dark().copyWith(
    pageTransitionsTheme: _pageTransitionsTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.navy,
      secondary: AppColors.lime,
      onSecondary: AppColors.navy,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.darkSurface,
    canvasColor: AppColors.darkSurface,
    cardColor: AppColors.darkSurfaceAlt,
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: AppColors.white),
      actionsIconTheme: IconThemeData(color: AppColors.white),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.darkSurface),
    splashColor: AppColors.primaryLight.withAlpha(36),
    highlightColor: AppColors.primaryLight.withAlpha(24),
    focusColor: AppColors.primaryLight.withAlpha(24),
    elevatedButtonTheme: _elevatedButtonTheme,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
    ),
    timePickerTheme: _timePickerTheme(Brightness.dark),
    datePickerTheme: _datePickerTheme(Brightness.dark),
    inputDecorationTheme: _inputDecorationTheme,
  );
}

const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoTransitionBuilder(),
    TargetPlatform.iOS: _NoTransitionBuilder(),
    TargetPlatform.windows: _NoTransitionBuilder(),
    TargetPlatform.linux: _NoTransitionBuilder(),
    TargetPlatform.macOS: _NoTransitionBuilder(),
  },
);

final _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.primaryLight20;
      }
      return AppColors.primary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.darkTextSecondary;
      }
      return AppColors.white;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
);

final _inputDecorationTheme = InputDecorationTheme(
  border: OutlineInputBorder(
    borderSide: const BorderSide(color: AppColors.border),
    borderRadius: BorderRadius.circular(16),
  ),
);

TimePickerThemeData _timePickerTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return TimePickerThemeData(
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
    hourMinuteColor:
        isDark ? AppColors.darkSurfaceAlt : AppColors.primaryLight10,
    hourMinuteTextColor:
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    dialBackgroundColor:
        isDark ? AppColors.darkSurfaceAlt : AppColors.greyLight,
    dialHandColor: isDark ? AppColors.primaryLight : AppColors.primary,
    dialTextColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    entryModeIconColor: isDark ? AppColors.primaryLight : AppColors.primary,
    dayPeriodColor:
        isDark ? AppColors.primaryLight20 : AppColors.primaryLight10,
    dayPeriodTextColor:
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    helpTextStyle: TextStyle(
      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    ),
  );
}

DatePickerThemeData _datePickerTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return DatePickerThemeData(
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
    headerForegroundColor:
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.white;
      }
      if (states.contains(WidgetState.disabled)) {
        return (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
            .withValues(alpha: 0.45);
      }
      return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.white;
      }
      return isDark ? AppColors.primaryLight : AppColors.primary;
    }),
    todayBorder: BorderSide(
      color: isDark ? AppColors.primaryLight : AppColors.primary,
    ),
    yearForegroundColor: WidgetStatePropertyAll(
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    ),
    weekdayStyle: TextStyle(
      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    ),
    cancelButtonStyle: TextButton.styleFrom(
      foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
    ),
    confirmButtonStyle: TextButton.styleFrom(
      foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
    ),
  );
}
