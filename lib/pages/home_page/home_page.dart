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
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/status_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/punch_button.dart';
import 'widgets/home_greeting.dart';
import 'widgets/home_history_section.dart';

class HomePage extends StatefulWidget {
  final String employeeName;
  final String profileImageUrl;
  final String logoAsset;
  final String employeeRole;

  /// Quando fornecido (ISO 8601), abre o histórico no mês dessa data.
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
  static const int _targetMinutesPerDay = 8 * 60; // 8 horas por dia

  late DateTime _currentMonth;

  /// Controlador do ListView principal para scroll programático.
  final ScrollController _scrollController = ScrollController();

  /// GlobalKey do widget HomeHistorySection para calcular posição de scroll.
  final GlobalKey _historySectionKey = GlobalKey();

  /// Dia que deve receber destaque após scroll (ISO 'yyyy-MM-dd').
  String? _highlightDayId;

  bool get _isAdmin => widget.employeeRole.toUpperCase().contains('ADM');

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName;
    profileImageUrl = widget.profileImageUrl;
    final now = DateTime.now();

    // Se recebeu uma data inicial (navegação de outra tela), usa o mês dela.
    final initDate = widget.initialHistoryDate != null
        ? DateTime.tryParse(widget.initialHistoryDate!)
        : null;
    if (initDate != null) {
      _currentMonth = DateTime(initDate.year, initDate.month);
      _highlightDayId = DateFormat('yyyy-MM-dd').format(initDate);
    } else {
      _currentMonth = DateTime(now.year, now.month);
    }

    // Timer que força rebuild a cada 30 s para atualizar tempo trabalhado.
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    _resolveUserData();

    // Dispara carregamento dos dados do dia (cubit persiste entre telas).
    context.read<PontoTodayCubit>().load();

    // Garante que o histórico esteja carregado para o mês selecionado.
    final historyBloc = context.read<PontoHistoryBloc>();
    if (historyBloc.state is PontoHistoryInitial ||
        historyBloc.currentMonth.year != _currentMonth.year ||
        historyBloc.currentMonth.month != _currentMonth.month) {
      historyBloc.add(LoadHistoryEvent(month: _currentMonth));
    }

    // O scroll até o DayCard é gerenciado por HomeHistorySection
    // (via BlocConsumer.listener quando o histórico terminar de carregar).

    // Atualiza silenciosamente as solicitações (já carregadas desde o splash).
    context.read<SolicitationBloc>().add(
          SilentReloadSolicitationsEvent(isAdmin: _isAdmin),
        );
    // Atualização periódica das notificações a cada 2 minutos.
    _solTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        context.read<SolicitationBloc>().add(
              SilentReloadSolicitationsEvent(isAdmin: _isAdmin),
            );
      }
    });
  }

  /// Resolve nome, foto e UID do SharedPreferences / FirebaseAuth.
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
      days.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return days;
  }

  //  Helpers de cálculo de horas trabalhadas

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

  //  Navegação de notificação para dia específico

  /// Chamado pelo botão de notificação na AppBar quando já estamos na home.
  /// Troca o mês, carrega o histórico e scrolla até a seção.
  void _goToDay(DateTime date) {
    final targetMonth = DateTime(date.year, date.month);
    final needsReload = _currentMonth.year != targetMonth.year ||
        _currentMonth.month != targetMonth.month;
    final newDayId = DateFormat('yyyy-MM-dd').format(date);

    // Zera o highlight primeiro — garante que didUpdateWidget detecte sempre
    // a mudança (null → valor), inclusive quando o mesmo dia é selecionado
    // repetidamente sem sair da tela.
    setState(() {
      _currentMonth = targetMonth;
      _highlightDayId = null;
    });

    // Define o destaque e dispara o reload (se necessário) no próximo frame,
    // após o rebuild com highlight=null ter sido confirmado pela UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _highlightDayId = newDayId);
      if (needsReload) {
        context
            .read<PontoHistoryBloc>()
            .add(LoadHistoryEvent(month: targetMonth));
      }
      // O scroll é gerenciado por HomeHistorySection:
      //  • já carregado → didUpdateWidget → _scrollToHighlightedDay()
      //  • carregando    → BlocConsumer.listener quando PontoHistoryLoaded
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    final pontoState = context.watch<PontoTodayCubit>().state;

    // Valores derivados do estado global do cubit + hora atual.
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
                      // PontoTodayCubit e PontoHistoryBloc atualizam-se
                      // automaticamente via PontoDataChangedCubit.
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
                      // Após editar/adicionar/remover ponto pelo histórico embutido,
                      // atualiza os dados do dia (saldo, status, etc.).
                      context.read<PontoTodayCubit>().refresh();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
