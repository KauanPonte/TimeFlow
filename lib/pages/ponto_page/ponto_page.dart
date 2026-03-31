import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/global_loading/global_loading_cubit.dart';
import '../../blocs/ponto_today/ponto_today_cubit.dart';
import '../../blocs/ponto_today/ponto_today_state.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/custom_snackbar.dart';
import '../../services/notification_service.dart';
import '../../services/ponto_validator.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/clock_card.dart';
import 'widgets/status_badge.dart';
import 'widgets/action_row.dart';
import 'widgets/today_timeline.dart';

class PontoPage extends StatefulWidget {
  const PontoPage({super.key});

  @override
  State<PontoPage> createState() => _PontoPageState();
}

class _PontoPageState extends State<PontoPage> {
  bool registering = false;
  bool _hojeEhFeriado = false;
  bool _validatingLocation = false;
  late DateTime _now;
  Timer? _clockTimer;
  String? _selectedWorkMode;

  /// Modo efetivo: usa o lock do cubit se existir, senão a seleção local.
  String? _effectiveWorkMode(PontoTodayState state) {
    return state.lockedWorkMode ?? _selectedWorkMode;
  }

  bool _isLocked(PontoTodayState state) {
    return state.lockedWorkMode != null;
  }

  @override
  void initState() {
    super.initState();
    _checkFeriadoStatus();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    NotificationService.scheduleDailyNotification(
      title: "Bom dia! ☀️",
      body: "Mais um day office! Já bateu seu ponto hoje?",
      hour: 9,
      minute: 0,
    );

    // Garante que o cubit tenha dados carregados.
    context.read<PontoTodayCubit>().load();
  }

  Future<void> _checkFeriadoStatus() async {
    bool feriado = await PontoService.isFeriado(DateTime.now());
    if (mounted) setState(() => _hojeEhFeriado = feriado);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _onWorkModeSelected(String mode) async {
    final firestoreValue = mode == 'Presencial' ? 'presencial' : 'remoto';

    if (mode == 'Presencial') {
      setState(() => _validatingLocation = true);
      try {
        final result = await LocationService.validatePresencialLocation();
        if (!mounted) return;
        setState(() => _validatingLocation = false);

        if (!result.success) {
          CustomSnackbar.showError(context, result.message);
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _validatingLocation = false);
        CustomSnackbar.showError(
            context, 'Erro ao validar localização. Tente novamente.');
        return;
      }
    }

    setState(() => _selectedWorkMode = firestoreValue);
  }

  Future<void> _registrar(String status, PontoTodayState state) async {
    final workMode = _effectiveWorkMode(state);
    if (workMode == null) return;

    setState(() => registering = true);
    final globalLoading = context.read<GlobalLoadingCubit>();

    // ---  TRAVA DE FERIADO AQUI ---
    globalLoading.show('Verificando calendário...');
    bool ehFeriado = await PontoService.isFeriado(DateTime.now());

    if (ehFeriado) {
      globalLoading.hide();
      if (mounted) {
        setState(() => registering = false);
        CustomSnackbar.showError(context,
            "Hoje é feriado/ponto facultativo. Registros não são permitidos.");
      }
      return; // Mata a execução aqui e não chama o cubit.registrar
    }
    final cubit = context.read<PontoTodayCubit>();
    globalLoading.show('Registrando ponto...');
    try {
      final pontoResult = await cubit.registrar(status, workMode: workMode);
      globalLoading.hide();
      if (mounted) {
        if (status == 'saida') {
          _selectedWorkMode = null;
        }

        setState(() => registering = false);
        if (pontoResult.success) {
          CustomSnackbar.showSuccess(context, pontoResult.message);
          String title;
          String body;
          switch (status) {
            case 'entrada':
              title = 'Ponto registrado';
              body = 'Bom trabalho! Sua entrada foi registrada.';
              break;
            case 'pausa':
              title = 'Pausa iniciada';
              body = 'Lembre-se de registrar o retorno depois.';
              break;
            case 'retorno':
              title = 'Retorno registrado';
              body = 'Continue com foco no seu trabalho!';
              break;
            case 'saida':
              title = 'Saída registrada';
              body = 'Bom descanso! Até amanhã.';
              break;
            default:
              return;
          }
          NotificationService.showInstantNotification(title: title, body: body);
        } else if (pontoResult.message.isNotEmpty) {
          CustomSnackbar.showError(context, pontoResult.message);
        }
      }
    } catch (_) {
      globalLoading.hide();
      if (mounted) setState(() => registering = false);
    }
  }

  String get _statusLabel {
    final ultimoTipo = context.read<PontoTodayCubit>().state.ultimoTipo;
    switch (ultimoTipo) {
      case 'entrada':
      case 'retorno':
        return 'Trabalhando...';
      case 'pausa':
        return 'Pausado';
      default:
        return 'Fora do expediente';
    }
  }

  /// Mapa com o último horário registrado de cada tipo hoje.
  Map<String, String> _hojeMapComputed(PontoTodayState state) {
    final map = <String, String>{};
    for (final ev in state.eventosHojeFormatados) {
      final tipo = ev['tipo'] ?? '';
      final hora = ev['hora'] ?? '';
      if (tipo.isNotEmpty && hora.isNotEmpty) map[tipo] = hora;
    }
    return map;
  }

  /// Próximas ações possíveis com base no último tipo registrado.
  Set<String> _proximasAcoes(PontoTodayState state) {
    return PontoValidator.proximosPermitidos(state.ultimoTipo);
  }

  Widget _buildWorkModeButton(
      String label, String value, PontoTodayState state) {
    final effective = _effectiveWorkMode(state);
    final isSelected = effective == value;
    final locked = _isLocked(state);
    final isDisabled = locked && !isSelected;

    return Expanded(
      child: InkWell(
        onTap: (locked || _validatingLocation)
            ? null
            : () => _onWorkModeSelected(label),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked && isSelected) ...[
                  Icon(Icons.lock,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textPrimary),
                  const SizedBox(width: 6),
                ],
                if (_validatingLocation && label == 'Presencial') ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isAdmin =
        (args?['employeeRole'] ?? '').toString().toUpperCase().contains('ADM');

    final pontoState = context.watch<PontoTodayCubit>().state;
    final hoje = _hojeMapComputed(pontoState);
    final proximas = _proximasAcoes(pontoState);
    final effectiveMode = _effectiveWorkMode(pontoState);
    final bool isPanelAccessible = effectiveMode != null && !_hojeEhFeriado;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fingerprint,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Bater Ponto',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        index: isAdmin ? 1 : 0,
        isAdmin: isAdmin,
        args: args,
      ),
      body: pontoState.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                context.read<PontoTodayCubit>().refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClockCard(now: _now),
                    const SizedBox(height: 16),

                    //  SELEÇÃO DE MODO DE TRABALHO
                    Text('Selecione o modo de trabalho',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildWorkModeButton(
                            'Presencial', 'presencial', pontoState),
                        const SizedBox(width: 12),
                        _buildWorkModeButton(
                            'Home Office', 'remoto', pontoState),
                      ],
                    ),
                    const SizedBox(height: 24),

                    StatusBadge(statusLabel: _statusLabel),
                    const SizedBox(height: 24),

                    Text(
                      'Registrar ponto',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPanelAccessible
                            ? AppColors.textPrimary
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Opacity(
                      opacity: isPanelAccessible ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: !isPanelAccessible,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 8,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: [
                              ActionRow(
                                label: 'Entrada',
                                icon: Icons.login_rounded,
                                accentColor: const Color(0xFF18A999),
                                done: hoje['entrada'] != null,
                                isNext: proximas.contains('entrada'),
                                time: hoje['entrada'],
                                isRegistering: registering,
                                isLast: false,
                                onTap: () => _registrar('entrada', pontoState),
                              ),
                              ActionRow(
                                label: 'Pausa',
                                icon: Icons.coffee_rounded,
                                accentColor: const Color(0xFF3DB2FF),
                                done: hoje['pausa'] != null,
                                isNext: proximas.contains('pausa'),
                                optional: true,
                                time: hoje['pausa'],
                                isRegistering: registering,
                                isLast: false,
                                onTap: () => _registrar('pausa', pontoState),
                              ),
                              ActionRow(
                                label: 'Retorno',
                                icon: Icons.replay_rounded,
                                accentColor: const Color(0xFFF7A500),
                                done: hoje['retorno'] != null,
                                isNext: proximas.contains('retorno'),
                                time: hoje['retorno'],
                                isRegistering: registering,
                                isLast: false,
                                onTap: () => _registrar('retorno', pontoState),
                              ),
                              ActionRow(
                                label: 'Saída',
                                icon: Icons.logout_rounded,
                                accentColor: const Color(0xFFE53935),
                                done: hoje['saida'] != null,
                                isNext: proximas.contains('saida'),
                                time: hoje['saida'],
                                isRegistering: registering,
                                isLast: true,
                                onTap: () => _registrar('saida', pontoState),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (pontoState.eventosHojeFormatados.isNotEmpty) ...[
                      Text(
                        'Registros de hoje',
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      TodayTimeline(eventos: pontoState.eventosHojeFormatados),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
