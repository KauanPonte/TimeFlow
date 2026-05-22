import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'abono_consulta_page.dart';
import 'abono_horario_page.dart';
import 'abono_pdf_page.dart';

class RequestAbonoPage extends StatefulWidget {
  final String? diaId;

  const RequestAbonoPage({super.key, this.diaId});

  @override
  State<RequestAbonoPage> createState() => _RequestAbonoPageState();
}

class _RequestAbonoPageState extends State<RequestAbonoPage> {
  static const _reasons = [
    'Consulta médica',
    'Doação de sangue',
    'Falecimento de parente',
    'Vestibular',
    'Aula',
    'Curso',
    'Folga',
    'Outros',
  ];

  // Motivos que creditam o dia inteiro (ponto facultativo) na aprovação
  static const _fullDayReasons = {
    'Falecimento de parente',
    'Vestibular',
    'Curso',
    'Folga',
    'Outros',
  };

  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  bool get _isOtherSelected => _selectedReason == 'Outros';
  bool get _canSubmit =>
      _selectedReason != null &&
      (!_isOtherSelected || _otherReasonController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final date = widget.diaId != null
        ? DateTime.tryParse(widget.diaId!)
        : DateTime.now();
    if (date == null || _selectedReason == null) return;

    final reason = _isOtherSelected
        ? _otherReasonController.text.trim()
        : _selectedReason!;

    context.read<JustificativaBloc>().add(
          SubmitJustificativaEvent(
            diaId: DateFormat('yyyy-MM-dd').format(date),
            justificativa: reason,
            isFullDayAbono: _fullDayReasons.contains(_selectedReason),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JustificativaBloc, JustificativaState>(
      listener: (context, state) {
        if (state is JustificativaActionSuccess) {
          CustomSnackbar.showSuccess(context, state.message);
          if (mounted) Navigator.pop(context);
        } else if (state is JustificativaError) {
          CustomSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
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
                child: const Icon(
                  Icons.request_page_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Solicitar Abono',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ListView(
            children: [
              Text(
                'Motivo do Abono',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    if (value == 'Consulta médica') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AbonoConsultaPage(diaId: widget.diaId),
                        ),
                      );
                    } else if (value == 'Doação de sangue') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AbonoPdfPage(
                            diaId: widget.diaId,
                            motivo: 'Doação de sangue',
                            titulo: 'Doação de Sangue',
                            icone: Icons.bloodtype_outlined,
                            isFullDayAbono: true,
                          ),
                        ),
                      );
                    } else if (value == 'Aula') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AbonoHorarioPage(
                            diaId: widget.diaId,
                            motivo: 'Aula',
                            titulo: 'Abono de Aula',
                            icone: Icons.school_outlined,
                          ),
                        ),
                      );
                    } else {
                      setState(() => _selectedReason = value);
                    }
                  },
                  title: Text(reason, style: AppTextStyles.bodyMedium),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const SizedBox(height: 20),
              if (_isOtherSelected) ...[
                Text(
                  'Qual outro motivo?',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otherReasonController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo do Outros',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.borderLight,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Enviar solicitação',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
