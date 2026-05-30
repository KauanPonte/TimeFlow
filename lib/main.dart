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
import 'package:flutter_application_appdeponto/blocs/abono/abono_event.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_state.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'package:flutter_application_appdeponto/repositories/auth_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/repositories/profile_repository.dart';
import 'package:flutter_application_appdeponto/repositories/solicitation_repository.dart';
import 'package:flutter_application_appdeponto/widgets/action_loading_overlay.dart';
import 'package:flutter_application_appdeponto/widgets/connectivity_guard.dart';
import 'pages/splash/splash_page.dart';
import 'services/notification_service.dart';
import 'pages/auth/welcome/welcome_page.dart';
import 'pages/auth/login/login_page.dart';
import 'pages/auth/register/register_page.dart';
import 'pages/auth/forgot_password/forgot_password_page.dart';
import 'pages/home_page/home_page.dart';
import 'pages/home_page/widgets/status_card.dart';
import 'pages/admin/home/home_admin_page.dart';
import 'pages/admin/users_management/users_management_page.dart';
import 'pages/ponto_page/ponto_page.dart';
import 'pages/profile_page/profile_page.dart';
import 'pages/history_page/history_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import 'package:flutter_application_appdeponto/theme/theme_controller.dart';
import 'package:flutter_application_appdeponto/widgets/instant_page_route.dart';

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
  await initializeDateFormatting('pt_BR');
  await NotificationService.init();
  try {
    await NotificationService.scheduleForLastLoggedUser();
  } catch (_) {}
  await themeController.load();
  // Pré-carrega a animação de engrenagens da home para aparecer instantânea.
  StatusCard.precacheGears();
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

/// Constrói o ThemeData para um brilho (claro/escuro), registrando a paleta
/// neutra correspondente como ThemeExtension (lida via `context.palette`).
ThemeData _appTheme(Brightness brightness, AppPalette palette) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      brightness: brightness,
      surface: palette.surface,
      onSurface: palette.textPrimary,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.primary),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x3362C1B1),
      selectionHandleColor: AppColors.primary,
    ),
    extensions: [palette],
    canvasColor: palette.surface,
    cardColor: palette.surface,
    dialogTheme: DialogThemeData(backgroundColor: palette.surface),
    datePickerTheme: DatePickerThemeData(backgroundColor: palette.surface),
    timePickerTheme: TimePickerThemeData(backgroundColor: palette.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: palette.surface),
    popupMenuTheme: PopupMenuThemeData(color: palette.surface),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoTransitionBuilder(),
        TargetPlatform.iOS: _NoTransitionBuilder(),
        TargetPlatform.windows: _NoTransitionBuilder(),
        TargetPlatform.linux: _NoTransitionBuilder(),
        TargetPlatform.macOS: _NoTransitionBuilder(),
      },
    ),
  );
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
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp(
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
              context.read<AbonoBloc>().reset();
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
                // Carrega atestados, justificativas e abonos para funcionários
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
                  final abonoState = context.read<AbonoBloc>().state;
                  if (abonoState is! AbonoLoaded && abonoState is! AbonoLoading) {
                    context
                        .read<AbonoBloc>()
                        .add(const LoadAbonosEvent(isAdmin: false));
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

          // Degradê de fundo global (bege → verde → teal) pintado atrás de
          // todas as telas; os scaffolds são transparentes para deixá-lo visível.
          return Container(
            decoration: BoxDecoration(gradient: context.palette.appBackground),
            child: ConnectivityGuard(child: appShell),
          );
        },
        theme: _appTheme(Brightness.light, AppPalette.light),
        darkTheme: _appTheme(Brightness.dark, AppPalette.dark),
        themeMode: themeController.mode,
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
              return InstantPageRoute(
                builder: (context) => HomeAdminPage(
                  employeeName: args["employeeName"] ?? "",
                  profileImageUrl: args["profileImageUrl"] ?? "",
                  employeeRole: employeeRole,
                ),
              );
            }

            return InstantPageRoute(
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
            final args = (settings.arguments as Map<String, dynamic>?) ?? {};
            return InstantPageRoute(
              builder: (context) => HomePage(
                employeeName: args["employeeName"] ?? "",
                profileImageUrl: args["profileImageUrl"] ?? "",
                employeeRole: args["employeeRole"] ?? "",
                initialHistoryDate: args["initialHistoryDate"] as String?,
              ),
            );
          }

          // Telas simples (sem argumentos) — também via InstantPageRoute
          // para que a navegação seja instantânea (sem ver a tela anterior).
          final builders = <String, WidgetBuilder>{
            "/": (context) => const SplashPage(),
            "/welcome": (context) => const WelcomePage(),
            "/login": (context) => const LoginPage(),
            "/register": (context) => const RegisterPage(),
            "/forgot-password": (context) => const ForgotPasswordPage(),
            "/ponto": (context) => const PontoPage(),
            "/profile": (context) => const ProfilePage(),
            "/history": (context) => const HistoryPage(),
            "/admin/users": (context) => const UsersManagementPage(),
          };
          final builder = builders[settings.name];
          if (builder != null) {
            return InstantPageRoute(settings: settings, builder: builder);
          }
          return null;
        },
        ),
      ),
    );
  }
}
