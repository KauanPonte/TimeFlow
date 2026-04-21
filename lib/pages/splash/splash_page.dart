import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_event.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_state.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_event.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_state.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/services/notification_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  final DateTime _splashStartedAt = DateTime.now();
  static const Duration _minSplashDuration = Duration(milliseconds: 3600);

  bool _isNavigating = false;
  bool _isPreloading = false;
  double _loadingProgress = 0.0;

  late final AnimationController _introController;
  late final AnimationController _ambientController;
  late final AnimationController _logoRotateController;
  late final AnimationController _exitController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotate;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _contentFade;
  late final Animation<double> _badgeFade;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _logoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _introController, curve: const Interval(0.0, 0.6)),
    );
    _logoRotate = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.017)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.017, end: 0.028)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.028, end: 0.028),
        weight: 36,
      ),
    ]).animate(_logoRotateController);
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic)),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );
    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.45, 1.0, curve: Curves.easeOut)),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _introController.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _exitController.dispose();
    _logoRotateController.dispose();
    _ambientController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _playExitTransition() async {
    if (!mounted) return;
    await _exitController.forward();
  }

  void _setLoadingProgress(double value) {
    if (!mounted) return;
    setState(() {
      _loadingProgress = value.clamp(0.0, 1.0);
    });
  }

  Future<T> _trackProgress<T>(Future<T> future, double weight) async {
    try {
      return await future;
    } finally {
      _setLoadingProgress(_loadingProgress + weight);
    }
  }

  Future<void> _checkLoginStatus() async {
    // Pequeno atraso para iniciar animação e então consultar autenticação.
    await Future.delayed(const Duration(milliseconds: 420));

    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AdminAuthenticated) {
      _bootstrapAndNavigate(
        isAdmin: true,
        userData: authState.userData,
        route: '/admin',
      );
      return;
    } else if (authState is UserAuthenticated) {
      final role = (authState.userData['role'] ?? '').toString();
      final isAdmin = role.toUpperCase().contains('ADM');
      _bootstrapAndNavigate(
        isAdmin: isAdmin,
        userData: authState.userData,
        route: '/home',
      );
      return;
    }

    // Dispatch event to check authentication status via BLoC se ainda não estiver autenticado.
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  Duration _remainingSplashTime() {
    final elapsed = DateTime.now().difference(_splashStartedAt);
    final remaining = _minSplashDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _waitForState<S>(
    Stream<S> stream,
    S currentState,
    bool Function(S) ready,
    Duration timeout,
  ) async {
    if (ready(currentState)) return;

    final completer = Completer<void>();
    late final StreamSubscription<S> sub;
    sub = stream.listen((state) {
      if (ready(state) && !completer.isCompleted) {
        completer.complete();
      }
    });

    await Future.any([completer.future, Future.delayed(timeout)]);
    await sub.cancel();
  }

  Future<void> _preloadCoreData({required bool isAdmin}) async {
    _isPreloading = true;
    if (mounted) setState(() {});

    final pontoTodayCubit = context.read<PontoTodayCubit>();
    final pontoHistoryBloc = context.read<PontoHistoryBloc>();
    final profileBloc = context.read<ProfileBloc>();
    final solicitationBloc = context.read<SolicitationBloc>();
    final atestadoBloc = context.read<AtestadoBloc>();
    final justificativaBloc = context.read<JustificativaBloc>();
    final adminHomeBloc = context.read<AdminHomeBloc>();

    _setLoadingProgress(0.08);

    final tasks = <Future<void>>[
      // Espera o load completo antes de navegar.
      _trackProgress(
        pontoTodayCubit.load(),
        0.18,
      ),
      _trackProgress(HistoryViewPreferenceRepository.initialize(), 0.10),
      _trackProgress(
        _waitForState<PontoHistoryState>(
          pontoHistoryBloc.stream,
          pontoHistoryBloc.state,
          (s) => s is PontoHistoryLoaded || s is PontoHistoryError,
          const Duration(seconds: 30),
        ),
        0.18,
      ),
      _trackProgress(
        _waitForState<ProfileState>(
          profileBloc.stream,
          profileBloc.state,
          (s) => s is ProfileLoaded || s is ProfileError,
          const Duration(seconds: 30),
        ),
        0.12,
      ),
      _trackProgress(
        _waitForState<SolicitationState>(
          solicitationBloc.stream,
          solicitationBloc.state,
          (s) => s is SolicitationLoaded || s is SolicitationError,
          const Duration(seconds: 30),
        ),
        0.12,
      ),
      _trackProgress(
        _waitForState<AtestadoState>(
          atestadoBloc.stream,
          atestadoBloc.state,
          (s) => s is AtestadoLoaded || s is AtestadoError,
          const Duration(seconds: 30),
        ),
        0.10,
      ),
      _trackProgress(
        _waitForState<JustificativaState>(
          justificativaBloc.stream,
          justificativaBloc.state,
          (s) => s is JustificativaLoaded || s is JustificativaError,
          const Duration(seconds: 30),
        ),
        0.12,
      ),
    ];

    profileBloc.add(const LoadProfileEvent());
    pontoHistoryBloc.add(LoadHistoryEvent(month: DateTime.now()));
    solicitationBloc.add(LoadSolicitationsEvent(isAdmin: isAdmin));
    atestadoBloc.add(LoadAtestadosEvent(isAdmin: isAdmin));
    justificativaBloc.add(LoadJustificativasEvent(isAdmin: isAdmin));

    if (isAdmin) {
      tasks.add(
        _trackProgress(
          _waitForState<AdminHomeState>(
            adminHomeBloc.stream,
            adminHomeBloc.state,
            (s) => s is AdminHomeLoaded || s is AdminHomeError,
            const Duration(seconds: 30),
          ),
          0.10,
        ),
      );
      adminHomeBloc.add(const LoadAdminStatsEvent());
    }

    await Future.wait(tasks);
    _setLoadingProgress(1.0);

    // Após carregar os dados, dispara notificações de registros incompletos
    // para que apareçam desde o início da sessão.
    _fireIncompleteRecordNotifications(pontoTodayCubit);
  }

  /// Verifica registros incompletos no estado do cubit e dispara
  /// notificações instantâneas para que o usuário saiba imediatamente.
  void _fireIncompleteRecordNotifications(PontoTodayCubit cubit) {
    final state = cubit.state;
    if (state.loading || state.registros.isEmpty) return;

    final now = DateTime.now();
    final hoje =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final incompletos = state.registros.entries.where((e) {
      if (e.key == hoje) return false;
      final m = e.value;
      if (m['entrada'] != null && m['saida'] == null) return true;
      if (m['pausa'] != null && m['retorno'] == null) return true;
      return false;
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (incompletos.isEmpty) return;

    final count = incompletos.length;
    const title = 'Registros incompletos';
    String body;
    if (count == 1) {
      final date = DateTime.tryParse(incompletos.first.key);
      final label = date != null
          ? DateFormat('dd/MM/yyyy', 'pt_BR').format(date)
          : incompletos.first.key;
      final m = incompletos.first.value;
      final motivo = (m['pausa'] != null && m['retorno'] == null)
          ? 'Pausa sem retorno'
          : 'Entrada sem saída';
      body = '$label — $motivo';
    } else {
      body = 'Você possui $count registros incompletos. Toque para verificar.';
    }

    NotificationService.showInstantNotification(title: title, body: body);
  }

  Future<void> _bootstrapAndNavigate({
    required bool isAdmin,
    required Map<String, dynamic> userData,
    required String route,
  }) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Verifica transporte de rede de forma instantânea (sem probe de DNS/socket)
    // para decidir se faz preload. Se não há transporte, pula preload para evitar
    // que o Firestore SDK tente reconectar e gere erros de DNS.
    bool hasTransport = true;
    try {
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List<ConnectivityResult>) {
        hasTransport = result.any((r) => r != ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        hasTransport = result != ConnectivityResult.none;
      }
    } catch (_) {}

    if (hasTransport) {
      try {
        await _preloadCoreData(isAdmin: isAdmin);
      } catch (_) {
        // Em caso de falha parcial de preload, segue fluxo para não bloquear acesso.
      }
    } else {
      _setLoadingProgress(1.0);
    }

    final remaining = _remainingSplashTime();
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    await _playExitTransition();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
      arguments: {
        'employeeName': userData['name'],
        'profileImageUrl': userData['profileImage'] ?? '',
        'employeeRole': userData['role'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AdminAuthenticated) {
          _bootstrapAndNavigate(
            isAdmin: true,
            userData: state.userData,
            route: '/admin',
          );
        } else if (state is UserAuthenticated) {
          final role = (state.userData['role'] ?? '').toString();
          final isAdmin = role.toUpperCase().contains('ADM');
          _bootstrapAndNavigate(
            isAdmin: isAdmin,
            userData: state.userData,
            route: '/home',
          );
        } else if (state is Unauthenticated) {
          () async {
            if (_isNavigating || !mounted) return;
            _isNavigating = true;
            final remaining = _remainingSplashTime();
            if (remaining > Duration.zero) {
              await Future.delayed(remaining);
            }
            await _playExitTransition();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/welcome');
            }
          }();
        }
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _exitFade,
          child: ScaleTransition(
            scale: _exitScale,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Stack(
                children: [
                  // Decorações de fundo com círculos suaves
                  Positioned(
                    left: -90,
                    top: -90,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -100,
                    bottom: -120,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  // Conteúdo central
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 18),
                            // Animação do logo com orbes e círculos concêntricos
                            FadeTransition(
                              opacity: _contentFade,
                              child: AnimatedBuilder(
                                animation: _ambientController,
                                builder: (context, child) {
                                  final v = _ambientController.value;
                                  final angle = v * 2 * math.pi;
                                  final orb1 = Offset(math.cos(angle) * 98,
                                      math.sin(angle) * 54);
                                  final orb2 = Offset(
                                      math.cos(angle + math.pi) * 84,
                                      math.sin(angle + math.pi) * 48);
                                  return SizedBox(
                                    width: 280,
                                    height: 280,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.rotate(
                                          angle: angle * 0.16,
                                          child: Container(
                                            width: 250,
                                            height: 250,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.surface
                                                    .withValues(alpha: 0.24),
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              radius: 0.92,
                                              colors: [
                                                AppColors.surface
                                                    .withValues(alpha: 0.26),
                                                AppColors.surface
                                                    .withValues(alpha: 0.06),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: orb1,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.78),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: orb2,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.surface
                                                  .withValues(alpha: 0.54),
                                            ),
                                          ),
                                        ),
                                        Transform.rotate(
                                          angle: angle * 0.35,
                                          child: Container(
                                            width: 275,
                                            height: 275,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.08),
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        FadeTransition(
                                          opacity: _logoFade,
                                          child: ScaleTransition(
                                            scale: _logoScale,
                                            child: AnimatedBuilder(
                                              animation: _logoRotate,
                                              builder: (context, child) {
                                                return Transform.rotate(
                                                  angle: _logoRotate.value *
                                                      math.pi,
                                                  child: SizedBox(
                                                    width: 160,
                                                    height: 160,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              18),
                                                      child: Image.asset(
                                                          'assets/app_icon/timeflow.png'),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Textos e progresso
                            SlideTransition(
                              position: _titleOffset,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: Text(
                                  'TimeFlow',
                                  style: AppTextStyles.h1.copyWith(
                                    color: AppColors.surface,
                                    letterSpacing: 1.2,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeTransition(
                              opacity: _contentFade,
                              child: Text(
                                'Controle de Ponto Simplificado',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.surface90,
                                  letterSpacing: 0.28,
                                ),
                              ),
                            ),
                            if (_isPreloading) ...[
                              const SizedBox(height: 42),
                              // Barra de progresso e badge de status
                              FadeTransition(
                                opacity: _badgeFade,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          minHeight: 10,
                                          value: _loadingProgress,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.16),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      '${(_loadingProgress * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Carregando recursos e preparando o fluxo...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.80),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
