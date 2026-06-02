import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_event.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_state.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/widgets/time_picker.dart';

class AbonoHorarioPage extends StatefulWidget {
  final String? diaId;
  final String motivo;
  final String titulo;
  final IconData icone;

  const AbonoHorarioPage({
    super.key,
    this.diaId,
    required this.motivo,
    required this.titulo,
    required this.icone,
  });

  @override
  State<AbonoHorarioPage> createState() => _AbonoHorarioPageState();
}

class _AbonoHorarioPageState extends State<AbonoHorarioPage> {
  // Horários manuais (usados apenas quando não há batida de saída registrada)
  TimeOfDay? _horaSaidaManual;
  TimeOfDay? _horaRetorno;

  // Dados carregados do Firestore ao abrir a tela
  bool _loadingDay = true;
  bool _submitting = false;
  bool _isAdmin = false;
  bool _hasExistingAbono = false;
  bool _hasSaidaRegistrada = false;
  String? _saidaRegistradaStr;
  int _workedMinutes = 0;
  int _workloadMinutes = 480;

  final _abonoRepository = AbonoRepository();

  final _fmtId = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  Future<void> _loadDayData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.diaId == null) {
      if (mounted) setState(() => _loadingDay = false);
      return;
    }

    if (mounted) {
      final authState = context.read<AuthBloc>().state;
      _isAdmin = authState is AdminAuthenticated ||
          (authState is UserAuthenticated &&
              (authState.userData['role'] ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('ADM'));
    }

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
        FirebaseFirestore.instance
            .collection('pontos')
            .doc(uid)
            .collection('dias')
            .doc(widget.diaId)
            .get(),
      ]);

      final abonoSnap = await FirebaseFirestore.instance
          .collection('abonos')
          .where('uid', isEqualTo: uid)
          .where('diaId', isEqualTo: widget.diaId)
          .limit(1)
          .get();
      final hasExisting = abonoSnap.docs.isNotEmpty;

      final userSnap = results[0];
      final daySnap  = results[1];

      final workload = (userSnap.data()?['workloadMinutes'] as int?) ??
          (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
          480;

      // Lê eventos do campo eventosCache (onde o repositório armazena)
      final raw = daySnap.data()?['eventosCache'];
      final List<Map<String, dynamic>> eventos = [];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            final at = e['at'];
            DateTime? dt;
            if (at is Timestamp) dt = at.toDate();
            if (dt != null) eventos.add({...e, 'at': dt});
          }
        }
        eventos.sort((a, b) =>
            (a['at'] as DateTime).compareTo(b['at'] as DateTime));
      }

      DateTime? openWork;
      int totalMin = 0;
      String? saidaStr;

      for (final ev in eventos) {
        final tipo = (ev['tipo'] ?? '').toString();
        final at   = ev['at'] as DateTime;

        if (tipo == 'entrada' || tipo == 'retorno') {
          openWork ??= at;
        } else if (tipo == 'pausa' || tipo == 'saida') {
          if (openWork != null && at.isAfter(openWork)) {
            totalMin += at.difference(openWork).inMinutes;
          }
          openWork = null;
          if (tipo == 'saida') {
            saidaStr =
                '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
          }
        }
      }

      if (mounted) {
        setState(() {
          _workloadMinutes    = workload;
          _workedMinutes      = totalMin;
          _hasSaidaRegistrada = saidaStr != null;
          _hasExistingAbono   = hasExisting;
          _saidaRegistradaStr = saidaStr;
          _loadingDay         = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDay = false);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  // Saída efetiva: batida real ou manual
  String? get _saidaEfetiva => _hasSaidaRegistrada
      ? _saidaRegistradaStr
      : (_horaSaidaManual != null ? _formatTime(_horaSaidaManual!) : null);

  // Com retorno: retorno − saída
  // Sem retorno + tem batida: carga − trabalhado (auto)
  // Sem retorno + sem batida: null (retorno obrigatório)
  int? get _abonoMinutes {
    if (_horaRetorno != null && _saidaEfetiva != null) {
      final parts    = _saidaEfetiva!.split(':');
      final saidaMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final retMin   = _horaRetorno!.hour * 60 + _horaRetorno!.minute;
      if (retMin <= saidaMin) return null;
      return retMin - saidaMin;
    }
    if (_horaRetorno == null && _hasSaidaRegistrada) {
      final restante = _workloadMinutes - _workedMinutes;
      return restante > 0 ? restante : 0;
    }
    return null;
  }

  Future<void> _pickSaidaManual() async {
    final picked = await showTimePicker24h(
        context, _horaSaidaManual ?? TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _horaSaidaManual = picked;
        if (_horaRetorno != null) {
          final s = picked.hour * 60 + picked.minute;
          final r = _horaRetorno!.hour * 60 + _horaRetorno!.minute;
          if (r <= s) _horaRetorno = null;
        }
      });
    }
  }

  Future<void> _pickRetorno() async {
    TimeOfDay initial = TimeOfDay.now();
    if (_saidaEfetiva != null) {
      final p = _saidaEfetiva!.split(':');
      initial =
          TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    final picked = await showTimePicker24h(context, initial);
    if (picked != null) setState(() => _horaRetorno = picked);
  }

  bool get _canSubmit {
    if (_loadingDay || _hasExistingAbono) return false;
    final abono = _abonoMinutes;
    return abono != null && abono > 0;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    final date = widget.diaId != null
        ? DateTime.tryParse(widget.diaId!)
        : DateTime.now();
    if (date == null) return;

    final diaId = _fmtId.format(date);
    final uid   = FirebaseAuth.instance.currentUser?.uid;

    if (_isAdmin && uid != null) {
      setState(() => _submitting = true);
      try {
        await _abonoRepository.adminApplyAbono(
          uid: uid,
          diaId: diaId,
          isFullDay: false,
          observacao: widget.motivo,
          abonoMinutesOverride: _abonoMinutes,
          dataInicio: _saidaEfetiva,
          dataFim: _horaRetorno != null ? _formatTime(_horaRetorno!) : null,
        );
        if (mounted) {
          context.read<AbonoBloc>().add(const LoadAbonosEvent(isAdmin: false));
          CustomSnackbar.showSuccess(context, 'Abono aplicado com sucesso.');
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _submitting = false);
          CustomSnackbar.showError(
              context, e.toString().replaceAll('Exception: ', ''));
        }
      }
      return;
    }

    context.read<AbonoBloc>().add(
          SubmitAbonoEvent(
            diaId: diaId,
            observacao: widget.motivo,
            dataInicio: _saidaEfetiva,
            dataFim: _horaRetorno != null ? _formatTime(_horaRetorno!) : null,
            abonoMinutes: _abonoMinutes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AbonoBloc, AbonoState>(
      listener: (context, state) {
        if (state is AbonoActionSuccess) {
          CustomSnackbar.showSuccess(context, state.message);
          if (mounted) Navigator.pop(context);
        } else if (state is AbonoError) {
          CustomSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
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
                child: Icon(widget.icone,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                widget.titulo,
                style: AppTextStyles.h3
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              'Período de ausência',
              style: AppTextStyles.titleSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Informe quando saiu e, se já retornou, o horário de retorno.',
              style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Saída',
                    required: true,
                    value: _horaSaida != null ? _formatTime(_horaSaida!) : null,
                    onTap: () => _pickTime(isSaida: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'Retorno',
                    required: false,
                    value: _horaRetorno != null
                        ? _formatTime(_horaRetorno!)
                        : null,
                    onTap: () => _pickTime(isSaida: false),
                  ),
                ),
              ],
            ),
            if (_durationMinutes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Duração da ausência: ',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.68)),
                    ),
                    Text(
                      _formatDuration(_durationMinutes!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_horaRetorno == null && _horaSaida != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sem retorno informado, o abono de horas será definido pelo administrador na aprovação.',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.68)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.border,
                  disabledForegroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Enviar solicitação',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'A solicitação será revisada pela administração.',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaidaField() {
    if (_hasSaidaRegistrada && _saidaRegistradaStr != null) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saída registrada',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(_saidaRegistradaStr!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary)),
                ),
                const Icon(Icons.lock_outline_rounded,
                    size: 15, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      );
    }

    return _TimeField(
      label: 'Saída',
      required: true,
      value: _horaSaidaManual != null
          ? _formatTime(_horaSaidaManual!)
          : null,
      onTap: _pickSaidaManual,
    );
  }

  Widget _buildAbonoPreview() {
    final abono = _abonoMinutes;
    final autoCalc = _horaRetorno == null && _hasSaidaRegistrada;

    if (abono == null) return const SizedBox.shrink();

    if (abono <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 15, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'A carga horária já foi cumprida — não há horas a abonar.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (autoCalc) ...[
            _previewRow('Horas trabalhadas',
                _formatMinutes(_workedMinutes), AppColors.textSecondary),
            const SizedBox(height: 4),
            _previewRow('Carga horária',
                _formatMinutes(_workloadMinutes), AppColors.textSecondary),
            const Divider(height: 16),
          ],
          _previewRow(
            autoCalc ? 'Abono necessário' : 'Duração da ausência',
            _formatMinutes(abono),
            AppColors.primary,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final bool required;
  final String? value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.required,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? AppColors.primary : AppColors.borderLight,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (required)
                  Text(' *',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Selecionar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Icon(Icons.access_time_rounded,
                    color: value != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
