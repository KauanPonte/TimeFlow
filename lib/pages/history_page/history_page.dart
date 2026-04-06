import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:intl/intl.dart';
import 'widgets/history_app_bar.dart';
import 'widgets/history_content_body.dart';
import 'widgets/history_shared_utils.dart';
import 'widgets/month_selector.dart';
import 'widgets/monthly_summary_card.dart';
import 'widgets/pdf_preview_modal.dart';

class HistoryPage extends StatelessWidget {
  final String? targetUid;
  final String? targetName;
  final String? targetProfileImage;
  final DateTime? initialDate;

  const HistoryPage({
    super.key,
    this.targetUid,
    this.targetName,
    this.targetProfileImage,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startMonth = initialDate != null
        ? DateTime(initialDate!.year, initialDate!.month)
        : DateTime(now.year, now.month);
    return BlocProvider(
      create: (_) => PontoHistoryBloc(
        repository: PontoHistoryRepository(),
        globalLoading: context.read<GlobalLoadingCubit>(),
      )..add(LoadHistoryEvent(uid: targetUid, month: startMonth)),
      child: _HistoryView(
        targetUid: targetUid,
        targetName: targetName,
        targetProfileImage: targetProfileImage,
        initialDate: initialDate,
      ),
    );
  }
}

class _HistoryView extends StatefulWidget {
  final String? targetUid;
  final String? targetName;
  final String? targetProfileImage;
  final DateTime? initialDate;

  const _HistoryView({
    this.targetUid, 
    this.targetName, 
    this.targetProfileImage,
    this.initialDate,
  });

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _viewPreferenceRepository = HistoryViewPreferenceRepository();
  final _justificativaRepository = JustificativaRepository();

  late DateTime _currentMonth;
  late DateTime _selectedCalendarDay;
  HistoryViewPreference _viewPreference =
      HistoryViewPreferenceRepository.currentMode;

  Map<DateTime, List<Map<String, dynamic>>> _allCalendarEvents = {};
  final Set<int> _loadedFixedHolidaysYears = {};

  /// Justificativas do funcionário sendo visualizado (admin mode).
  Map<String, JustificativaModel> _adminJustificativas = {};
  
  Future<MesResumo>? _mesResumoFuture;
  Uint8List? _profileBytesCache;
  
  // Cache para persistência durante a navegação entre meses
  final Map<String, Map<String, String>> _blockedDaysCache = {};
  final Map<String, MesResumo> _resumoCache = {};
  final Map<String, List<JustificativaModel>> _justificativasCache = {};

  bool get isAdmin => widget.targetUid != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month)
        : DateTime(now.year, now.month);
    _selectedCalendarDay =
        HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    _profileBytesCache = _decodeProfileImage(widget.targetProfileImage);
    _loadCalendarBlockedDays();
    _loadMesResumo();
  }

  @override
  void didUpdateWidget(_HistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProfileImage != widget.targetProfileImage) {
      setState(() {
        _profileBytesCache = _decodeProfileImage(widget.targetProfileImage);
      });
    }
  }

  void _loadMesResumo() {
    final uid = widget.targetUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = "${uid}_${DateFormat('yyyy-MM').format(_currentMonth)}";
    
    if (_resumoCache.containsKey(key)) {
      setState(() {
        _mesResumoFuture = Future.value(_resumoCache[key]);
      });
      return;
    }

    setState(() {
      _mesResumoFuture = PontoService.calcularResumoMensal(uid, _currentMonth).then((resumo) {
        _resumoCache[key] = resumo;
        return resumo;
      });
    });
  }

  Future<void> _loadCalendarBlockedDays() async {
    final year = _currentMonth.year;
    final key = DateFormat('yyyy-MM').format(_currentMonth);

    if (_blockedDaysCache.containsKey(key) && _loadedFixedHolidaysYears.contains(year)) {
      return;
    }

    try {
      final fixos = PontoService.getBrazilHolidays(year);
      
      final Map<DateTime, List<Map<String, dynamic>>> newEvents = Map.from(_allCalendarEvents);

      fixos.forEach((date, name) {
        final cleanDate = DateTime(date.year, date.month, date.day);
        if (!newEvents.containsKey(cleanDate)) {
           newEvents[cleanDate] = [{'title': name, 'type': 'feriado'}];
        }
      });
      _loadedFixedHolidaysYears.add(year);

      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] == null) continue;
        final date = (data['date'] as Timestamp).toDate();
        final cleanDate = DateTime(date.year, date.month, date.day);
        
        if (newEvents[cleanDate] == null) {
          newEvents[cleanDate] = [data];
        } else {
          final exists = newEvents[cleanDate]!.any((ev) => ev['id'] == doc.id || (ev['title'] == data['title'] && ev['type'] == data['type']));
          if (!exists) {
            newEvents[cleanDate]!.add(data);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allCalendarEvents = newEvents;
        });
      }

      final blockedStrings = <String, String>{};
      _allCalendarEvents.forEach((date, evs) {
        if (date.year == _currentMonth.year && date.month == _currentMonth.month) {
          final id = HistorySharedUtils.toDayId(date);
          blockedStrings[id] = evs.first['title']?.toString() ?? 'Feriado';
        }
      });
      _blockedDaysCache[key] = blockedStrings;

    } catch (e) {
      debugPrint("Erro ao carregar eventos: $e");
    }

    if (isAdmin) {
      _loadAdminJustificativas();
    }
  }

  Future<void> _loadAdminJustificativas() async {
    if (widget.targetUid == null) return;
    
    final key = "${widget.targetUid}_${DateFormat('yyyy-MM').format(_currentMonth)}";
    if (_justificativasCache.containsKey(key)) {
      setState(() {
        _adminJustificativas = {for (final j in _justificativasCache[key]!) j.diaId: j};
      });
      return;
    }

    try {
      final list = await _justificativaRepository
          .getJustificativasForEmployee(widget.targetUid!);
      if (mounted) {
        _justificativasCache[key] = list;
        setState(() {
          _adminJustificativas = {for (final j in list) j.diaId: j};
        });
      }
    } catch (_) {}
  }

  Future<void> _setPreferredView(HistoryViewPreference value) async {
    if (_viewPreference == value) return;
    setState(() => _viewPreference = value);
    try {
      await _viewPreferenceRepository.savePreferredMode(value);
    } catch (_) {}
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
    _loadCalendarBlockedDays(); 
    _loadMesResumo();
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
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
    _loadCalendarBlockedDays(); 
    _loadMesResumo();
  }

  Future<void> _refreshHistory() async {
    _blockedDaysCache.clear();
    _resumoCache.clear();
    _justificativasCache.clear();

    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(
            uid: widget.targetUid,
            month: _currentMonth,
          ),
        );
    _loadCalendarBlockedDays();
    if (isAdmin) await _loadAdminJustificativas();
    _loadMesResumo();
  }

  Uint8List? _decodeProfileImage(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final cleaned = data.contains(',') ? data.split(',').last : data;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isAdmin ? (widget.targetName ?? 'Usuário') : 'Meu Histórico';
    final subTitle = isAdmin ? 'Histórico de Pontos' : null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: HistoryAppBar(
        title: title,
        subTitle: subTitle,
        profileBytes: _profileBytesCache,
        viewPreference: _viewPreference,
        onViewChanged: _setPreferredView,
      ),
      floatingActionButton: BlocBuilder<PontoHistoryBloc, PontoHistoryState>(
        builder: (context, state) {
          if (state is PontoHistoryLoaded) {
            return FloatingActionButton(
              onPressed: () => PdfPreviewModal.show(
                context: context,
                currentMonth: _currentMonth,
                punchRecords: state.daysMap,
                mesResumoFuture: _mesResumoFuture,
                allCalendarEvents: _allCalendarEvents,
                userName: widget.targetName ?? 'Usuário',
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocConsumer<PontoHistoryBloc, PontoHistoryState>(
        listener: (context, state) {
          if (state is PontoHistoryActionSuccess) {
            CustomSnackbar.showSuccess(context, state.message);
          } else if (state is PontoHistoryActionError) {
            CustomSnackbar.showError(context, state.message);
          } else if (state is PontoHistoryError) {
            CustomSnackbar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              MonthSelector(
                currentMonth: _currentMonth,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
              ),
              MonthlySummaryCard(mesResumoFuture: _mesResumoFuture),
              Expanded(
                child: HistoryContentBody(
                  state: state,
                  currentMonth: _currentMonth,
                  selectedCalendarDay: _selectedCalendarDay,
                  viewPreference: _viewPreference,
                  isAdmin: isAdmin,
                  targetUid: widget.targetUid,
                  allCalendarEvents: _allCalendarEvents,
                  adminJustificativas: _adminJustificativas,
                  justificativaRepository: _justificativaRepository,
                  onDaySelected: (day) =>
                      setState(() => _selectedCalendarDay = day),
                  onRefresh: _refreshHistory,
                  onAdminJustificativasReloaded: _loadAdminJustificativas,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
