//import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/widgets/main_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/status_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/punch_button.dart';

import 'widgets/home_greeting.dart';
import 'widgets/home_history_section.dart';
import 'pages/calendar_page.dart';

class HomePage extends StatefulWidget {
  final String employeeName;
  final String profileImageUrl;
  final String logoAsset;
  final String employeeRole;

  final String? initialHistoryDate;

  const HomePage({
    super.key,
    required this.employeeName,
    required this.profileImageUrl,
    required this.employeeRole,
    this.logoAsset = 'assets/app_icon/timeflow_background.png',
    this.initialHistoryDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String employeeName = '';
  String profileImageUrl = '';
  String? _uid;
  Timer? _tickTimer;
  Timer? _solTimer;
  static const int _targetMinutesPerDay = 8 * 60;

  late DateTime _currentMonth;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historySectionKey = GlobalKey();
  String? _highlightDayId;

  bool get _isAdmin => widget.employeeRole.toUpperCase().contains('ADM');

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName;
    profileImageUrl = widget.profileImageUrl;
    final now = DateTime.now();

    final initDate = widget.initialHistoryDate != null
        ? DateTime.tryParse(widget.initialHistoryDate!)
        : null;

    if (initDate != null) {
      _currentMonth = DateTime(initDate.year, initDate.month);
      // Alterado para CustomDateFormatter para seguir a lógica da Alteração 2
      final newDayId = CustomDateFormatter('yyyy-MM-dd').format(initDate);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _highlightDayId = newDayId);
      });
    } else {
      _currentMonth = DateTime(now.year, now.month);
    }

    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    _resolveUserData();
    context.read<PontoTodayCubit>().load();

    final historyBloc = context.read<PontoHistoryBloc>();
    if (historyBloc.state is PontoHistoryInitial ||
        historyBloc.currentMonth.year != _currentMonth.year ||
        historyBloc.currentMonth.month != _currentMonth.month) {
      historyBloc.add(LoadHistoryEvent(month: _currentMonth));
    }

    context.read<SolicitationBloc>().add(
          SilentReloadSolicitationsEvent(isAdmin: _isAdmin),
        );
    _solTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        context.read<SolicitationBloc>().add(
              SilentReloadSolicitationsEvent(isAdmin: _isAdmin),
            );
      }
    });
  }

  Future<void> _resolveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (employeeName.isEmpty) {
      employeeName = prefs.getString('employee_name') ?? '';
    }
    if (profileImageUrl.isEmpty) {
      profileImageUrl = prefs.getString('profile_image_path') ?? '';
    }
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _uid ??= prefs.getString('userUid');
    if ((_uid ?? '').isEmpty) _uid = null;
    if (mounted) setState(() {});
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    context
        .read<PontoHistoryBloc>()
        .add(LoadHistoryEvent(month: _currentMonth));
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }
    setState(() {
      _currentMonth = nextMonth;
    });
    context
        .read<PontoHistoryBloc>()
        .add(LoadHistoryEvent(month: _currentMonth));
  }

  List<String> _generateMonthDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final days = <String>[];
    for (int d = lastDay; d >= 1; d--) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      if (date.isAfter(today)) continue;
      // Alterado para CustomDateFormatter
      days.add(CustomDateFormatter('yyyy-MM-dd').format(date));
    }
    return days;
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

  String _formatMinutes(int totalMin) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m}m';
  }

  int _computeWorkedMinutes(List<Map<String, dynamic>> eventos,
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
    _solTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToDay(DateTime date) {
    final targetMonth = DateTime(date.year, date.month);
    final needsReload = _currentMonth.year != targetMonth.year ||
        _currentMonth.month != targetMonth.month;
    // Alterado para CustomDateFormatter
    final newDayId = CustomDateFormatter('yyyy-MM-dd').format(date);

    setState(() {
      _currentMonth = targetMonth;
      _highlightDayId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _highlightDayId = newDayId);
      if (needsReload) {
        context
            .read<PontoHistoryBloc>()
            .add(LoadHistoryEvent(month: targetMonth));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    final pontoState = context.watch<PontoTodayCubit>().state;

    final now = DateTime.now();
    final statusLabel = _labelFromUltimoTipo(pontoState.ultimoTipo);
    final workedMinutes =
        _computeWorkedMinutes(pontoState.eventosHoje, now: now);
    final todayWorkedDisplay = _formatMinutes(workedMinutes);
    final workProgress = _targetMinutesPerDay == 0
        ? 0.0
        : (workedMinutes / _targetMinutesPerDay).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: MainAppBar(
        subtitle: 'Meu Ponto',
        onNotificationDayTap: _goToDay,
      ),
      bottomNavigationBar: BottomNav(
        index: isAdmin ? 1 : 0,
        isAdmin: isAdmin,
        args: {
          'employeeName': employeeName,
          'profileImageUrl': profileImageUrl,
          'employeeRole': widget.employeeRole,
        },
      ),
      body: pontoState.loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                context.read<PontoTodayCubit>().refresh();
                context
                    .read<PontoHistoryBloc>()
                    .add(const SilentReloadHistoryEvent());
              },
              color: AppColors.primary,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  HomeGreeting(employeeName: employeeName),
                  const SizedBox(height: 24),
                  StatusCard(
                    statusLabel: statusLabel,
                    todayWorkedDisplay: todayWorkedDisplay,
                    workProgress: workProgress,
                    workedMinutes:
                        workedMinutes, // Passando o valor para o novo StatusCard
                  ),
                  const SizedBox(height: 16),
                  BalanceCard(monthBalance: pontoState.monthBalance),
                  const SizedBox(height: 24),
                  PunchButton(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/ponto',
                        arguments: {
                          'employeeName': employeeName,
                          'profileImageUrl': profileImageUrl,
                          'employeeRole': widget.employeeRole,
                        },
                      );
                    },
                  ),
                  HomeHistorySection(
                    key: _historySectionKey,
                    currentMonth: _currentMonth,
                    highlightDayId: _highlightDayId,
                    onPrevious: _goToPreviousMonth,
                    onNext: _goToNextMonth,
                    isAdmin: isAdmin,
                    uid: _uid,
                    generateMonthDays: _generateMonthDays,
                    onActionSuccess: () {
                      context.read<PontoTodayCubit>().refresh();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class CustomDateFormatter {
  final String pattern;
  CustomDateFormatter(this.pattern);

  String format(DateTime date) {
    if (pattern == 'yyyy-MM-dd') {
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '${day}_${month}_$year';
  }
}
