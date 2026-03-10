import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/global_loading/global_loading_cubit.dart';
import '../../blocs/ponto_data/ponto_data_changed_cubit.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/custom_snackbar.dart';
import '../../services/ponto_service.dart';
import '../../services/notification_service.dart';
import '../../services/ponto_validator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/clock_card.dart';
import 'widgets/status_badge.dart';
import 'widgets/action_row.dart';
import 'widgets/incompletos_card.dart';
import 'widgets/today_timeline.dart';

class PontoPage extends StatefulWidget {
  const PontoPage({super.key});

  @override
  State<PontoPage> createState() => _PontoPageState();
}

class _PontoPageState extends State<PontoPage> {
  Map<String, Map<String, String>> registros = {};
  List<Map<String, String>> _eventosHojeList = [];
  String? _ultimoTipo;
  bool loading = true;
  bool registering = false;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
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

    _loadRegistros();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRegistros() async {
    setState(() => loading = true);
    registros = await PontoService.loadRegistros();
    _eventosHojeList = await PontoService.loadEventosHojeFormatados();
    _ultimoTipo = await PontoService.getUltimoTipoHoje();
    setState(() => loading = false);
  }

  /// Atualiza os dados sem exibir o loading da página inteira.
  Future<void> _refreshRegistros() async {
    registros = await PontoService.loadRegistros();
    _eventosHojeList = await PontoService.loadEventosHojeFormatados();
    _ultimoTipo = await PontoService.getUltimoTipoHoje();
    if (mounted) setState(() {});
  }

  Future<void> _registrar(String status) async {
    setState(() => registering = true);
    // Captura referências antes dos gaps assíncronos.
    final globalLoading = context.read<GlobalLoadingCubit>();
    final pontoDataChanged = context.read<PontoDataChangedCubit>();
    globalLoading.show('Registrando ponto...');
    var pontoResult = const PontoResult(success: false, message: '');
    try {
      pontoResult = await PontoService.registrarPonto(status);
      if (pontoResult.success) {
        await _refreshRegistros();
        // Notifica outras telas (ex: Meu Ponto) para atualizar silenciosamente.
        pontoDataChanged.notifyChanged();
      }
    } finally {
      globalLoading.hide();
      if (mounted) {
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
    }
  }

  String get _statusLabel {
    switch (_ultimoTipo) {
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
  /// Usado nos ActionRows para exibir "done" e a hora.
  Map<String, String> get _hojeMapComputed {
    final map = <String, String>{};
    for (final ev in _eventosHojeList) {
      final tipo = ev['tipo'] ?? '';
      final hora = ev['hora'] ?? '';
      if (tipo.isNotEmpty && hora.isNotEmpty) map[tipo] = hora;
    }
    return map;
  }

  /// Chave do dia de hoje no mapa de registros (formato yyyy-MM-dd).
  String get _hojeKey {
    final y = _now.year.toString().padLeft(4, '0');
    final m = _now.month.toString().padLeft(2, '0');
    final d = _now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Próximas ações possíveis com base no último tipo registrado.
  Set<String> get _proximasAcoes {
    return PontoValidator.proximosPermitidos(_ultimoTipo);
  }

  /// Dias passados com sequência incompleta (entrada sem saída ou pausa sem retorno).
  List<MapEntry<String, Map<String, String>>> get _incompletos {
    final hoje = _hojeKey;
    return registros.entries.where((e) {
      if (e.key == hoje) return false; // hoje não conta como incompleto
      final m = e.value;
      final temEntrada = m['entrada'] != null;
      final temSaida = m['saida'] != null;
      final temPausa = m['pausa'] != null;
      final temRetorno = m['retorno'] != null;
      if (temEntrada && !temSaida) return true;
      if (temPausa && !temRetorno) return true;
      return false;
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isAdmin =
        (args?['employeeRole'] ?? '').toString().toUpperCase().contains('ADM');
    final hoje = _hojeMapComputed;
    final proximas = _proximasAcoes;
    final incompletos = _incompletos;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ),
      bottomNavigationBar: BottomNav(
        index: isAdmin ? 1 : 0,
        isAdmin: isAdmin,
        args: args,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshRegistros,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Relógio ──────────────────────────────────────
                    ClockCard(now: _now),
                    const SizedBox(height: 16),

                    // ── Status do dia ────────────────────────────────
                    StatusBadge(statusLabel: _statusLabel),
                    const SizedBox(height: 24),

                    // ── Registros incompletos de dias anteriores ───────
                    if (incompletos.isNotEmpty) ...[
                      IncompletosCard(incompletos: incompletos),
                      const SizedBox(height: 16),
                    ],

                    // ── Botões de ação ───────────────────────────────
                    Text(
                      'Registrar ponto',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
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
                            onTap: () => _registrar('entrada'),
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
                            onTap: () => _registrar('pausa'),
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
                            onTap: () => _registrar('retorno'),
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
                            onTap: () => _registrar('saida'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Timeline de hoje ─────────────────────────────
                    if (_eventosHojeList.isNotEmpty) ...[
                      Text(
                        'Registros de hoje',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TodayTimeline(eventos: _eventosHojeList),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
