import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/main_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ponto_service.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/status_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/punch_button.dart';

class HomePage extends StatefulWidget {
  final String employeeName;
  final String profileImageUrl;
  final String logoAsset;
  final String employeeRole;

  const HomePage({
    super.key,
    required this.employeeName,
    required this.profileImageUrl,
    required this.employeeRole,
    this.logoAsset = 'assets/app_icon/timeflow_background.png',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Map<String, Map<String, String>> registros = {};
  List<Map<String, dynamic>> eventosHoje = [];
  String statusLabel = 'Fora do expediente';
  String? ultimoTipoHoje;
  double monthBalance = 0.0;
  String employeeName = '';
  String profileImageUrl = '';
  String todayWorkedDisplay = '0h 0m';
  bool loading = true;
  Timer? _tickTimer;
  static const int _targetMinutesPerDay = 8 * 60; // 8 horas por dia
  double workProgress = 0.0;

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName;
    profileImageUrl = widget.profileImageUrl;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    //registros = await PontoService.loadRegistros();

    eventosHoje = await PontoService.loadEventosHoje();
    ultimoTipoHoje = await PontoService.getUltimoTipoHoje();

    final now = DateTime.now();
    statusLabel = _labelFromUltimoTipo(ultimoTipoHoje);
    todayWorkedDisplay = _computeWorkedFromEventos(eventosHoje, now: now);

    final minutesNow = _computeWorkedMinutesFromEventos(eventosHoje, now: now);
    workProgress = (_targetMinutesPerDay == 0)
        ? 0.0
        : (minutesNow / _targetMinutesPerDay).clamp(0.0, 1.0);

    final prefs = await SharedPreferences.getInstance();
    monthBalance = await PontoService.getSaldoMesAtualHoras();

    if (employeeName.isEmpty) {
      employeeName = prefs.getString('employee_name') ?? '';
    }
    if (profileImageUrl.isEmpty) {
      profileImageUrl = prefs.getString('profile_image_path') ?? '';
    }

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;

      final now2 = DateTime.now();
      final minutes2 = _computeWorkedMinutesFromEventos(eventosHoje, now: now2);
      final display2 = _computeWorkedFromEventos(eventosHoje, now: now2);

      setState(() {
        todayWorkedDisplay = display2;
        workProgress = (_targetMinutesPerDay == 0)
            ? 0.0
            : (minutes2 / _targetMinutesPerDay).clamp(0.0, 1.0);
      });
    });

    setState(() => loading = false);
  }

  String _labelFromUltimoTipo(String? ultimo) {
    switch (ultimo) {
      case 'entrada':
      case 'retorno':
        return 'Trabalhando...';
      case 'pausa':
        return 'Pausado';
      case 'saida':
      default:
        return 'Fora do expediente';
    }
  }

  String _computeWorkedFromEventos(List<Map<String, dynamic>> eventos,
      {required DateTime now}) {
    final totalMin = _computeWorkedMinutesFromEventos(eventos, now: now);
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m}m';
  }

  int _computeWorkedMinutesFromEventos(List<Map<String, dynamic>> eventos,
      {required DateTime now}) {
    DateTime? openWork;
    Duration total = Duration.zero;

    DateTime? tsToDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return null;
    }

    for (final ev in eventos) {
      final tipo = (ev['tipo'] ?? '').toString();
      final at = tsToDate(ev['at']);
      if (at == null) continue;

      if (tipo == 'entrada' || tipo == 'retorno') {
        openWork ??= at;
      } else if (tipo == 'pausa' || tipo == 'saida') {
        if (openWork != null && at.isAfter(openWork)) {
          total += at.difference(openWork);
        }
        openWork = null;
      }
    }

    if (openWork != null && now.isAfter(openWork)) {
      total += now.difference(openWork);
    }

    return total.inMinutes;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.employeeRole.toUpperCase().contains('ADM');

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const MainAppBar(subtitle: 'Meu Ponto'),
      bottomNavigationBar: BottomNav(
        index: isAdmin ? 1 : 1,
        isAdmin: isAdmin,
        args: {
          'employeeName': employeeName,
          'profileImageUrl': profileImageUrl,
          'employeeRole': widget.employeeRole,
        },
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Saudação
                  Text(
                    'Olá, ${employeeName.isNotEmpty ? employeeName : 'Colaborador'}!',
                    style:
                        AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aqui está seu resumo de hoje',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  StatusCard(
                    statusLabel: statusLabel,
                    todayWorkedDisplay: todayWorkedDisplay,
                    workProgress: workProgress,
                  ),

                  const SizedBox(height: 16),

                  BalanceCard(monthBalance: monthBalance),

                  const SizedBox(height: 24),

                  PunchButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/ponto',
                      arguments: {
                        'employeeName': employeeName,
                        'profileImageUrl': profileImageUrl,
                        'employeeRole': widget.employeeRole,
                      },
                    ).then((_) => _loadAll()),
                  ),
                ],
              ),
            ),
    );
  }
}
