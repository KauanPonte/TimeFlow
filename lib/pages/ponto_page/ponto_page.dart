import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
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
  String? _workMode;

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

  Future<void> _registrar(String status) async {
    setState(() => registering = true);
    await PontoService.registrarPonto(context, status);
    await _loadRegistros();

    if (status == 'saida') {
      _workMode = null;
    }

    setState(() => registering = false);

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

  Map<String, String> get _hojeMapComputed {
    final map = <String, String>{};
    for (final ev in _eventosHojeList) {
      final tipo = ev['tipo'] ?? '';
      final hora = ev['hora'] ?? '';
      if (tipo.isNotEmpty && hora.isNotEmpty) map[tipo] = hora;
    }
    return map;
  }

  String get _hojeKey {
    final y = _now.year.toString().padLeft(4, '0');
    final m = _now.month.toString().padLeft(2, '0');
    final d = _now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Set<String> get _proximasAcoes {
    Set<String> permitidos = PontoValidator.proximosPermitidos(_ultimoTipo);
    if (_ultimoTipo == 'saida') {
      permitidos.add('entrada');
    }
    return permitidos;
  }

  List<MapEntry<String, Map<String, String>>> get _incompletos {
    final hoje = _hojeKey;
    return registros.entries.where((e) {
      if (e.key == hoje) return false;
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

  Widget _buildWorkModeButton(String mode) {
    final isSelected = _workMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _workMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            mode,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
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
    final hoje = _hojeMapComputed;
    final proximas = _proximasAcoes;
    final incompletos = _incompletos;
    final bool isPanelAccessible = _workMode != null;

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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRegistros,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClockCard(now: _now),
                    const SizedBox(height: 16),

                    // ── SELEÇÃO DE MODO DE TRABALHO ──────────────────────
                    Text('Selecione o modo de trabalho',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildWorkModeButton('Presencial'),
                        const SizedBox(width: 12),
                        _buildWorkModeButton('Home Office'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    StatusBadge(statusLabel: _statusLabel),
                    const SizedBox(height: 24),

                    if (incompletos.isNotEmpty) ...[
                      IncompletosCard(incompletos: incompletos),
                      const SizedBox(height: 16),
                    ],

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
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_eventosHojeList.isNotEmpty) ...[
                      Text(
                        'Registros de hoje',
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
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
