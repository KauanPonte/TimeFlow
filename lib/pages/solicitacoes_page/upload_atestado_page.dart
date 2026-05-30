import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class UploadAtestadoPage extends StatefulWidget {
  const UploadAtestadoPage({super.key});

  @override
  State<UploadAtestadoPage> createState() => _UploadAtestadoPageState();
}

class _UploadAtestadoPageState extends State<UploadAtestadoPage> {
  bool _isAdmin = false;
  String? _fileName;
  Uint8List? _fileBytes;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final _fmt = DateFormat('dd/MM/yyyy');
  final _fmtId = DateFormat('yyyy-MM-dd');

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileName = result.files.single.name;
        _fileBytes = result.files.single.bytes;
      });
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = _resolveIsAdmin(context);
      if (mounted) {
        setState(() {
          _isAdmin = admin;
        });
        if (_isAdmin) {
          context.read<AtestadoBloc>().add(
                const LoadAtestadosEvent(
                  isAdmin: true,
                  includeReviewed: true,
                ),
              );
        }
      }
    });
  }

  bool _resolveIsAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AdminAuthenticated) return true;
    if (authState is UserAuthenticated) {
      final role = (authState.userData['role'] ?? '').toString();
      return role.toUpperCase().contains('ADM');
    }
    return false;
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final initial = isInicio
        ? (_dataInicio ?? DateTime.now())
        : (_dataFim ?? _dataInicio ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: context.palette.surface,
                  onSurface: context.palette.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
          if (_dataFim != null && _dataFim!.isBefore(picked)) {
            _dataFim = null;
          }
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  bool get _canSubmit =>
      _fileName != null &&
      _fileBytes != null &&
      _dataInicio != null &&
      _dataFim != null;

  void _submit() {
    if (!_canSubmit) return;
    context.read<AtestadoBloc>().add(
          SubmitAtestadoEvent(
            dataInicio: _fmtId.format(_dataInicio!),
            dataFim: _fmtId.format(_dataFim!),
            fileName: _fileName!,
            fileBytes: _fileBytes!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AtestadoBloc, AtestadoState>(
      listener: (context, state) {
        if (state is AtestadoActionSuccess) {
          CustomSnackbar.showSuccess(context, state.message);
          if (_isAdmin) {
            context.read<AtestadoBloc>().add(
                  const LoadAtestadosEvent(
                    isAdmin: true,
                    includeReviewed: true,
                  ),
                );
          } else {
            Navigator.pop(context);
          }
        } else if (state is AtestadoError) {
          CustomSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: context.palette.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: context.palette.textPrimary, size: 20),
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
                  Icons.cloud_upload_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isAdmin ? 'Atestados' : 'Novo Atestado',
                style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
              ),
            ],
          ),
        ),
        body: BlocBuilder<AtestadoBloc, AtestadoState>(
          builder: (context, state) {
            final pendingAtestados = <AtestadoModel>[];
            if (_isAdmin) {
              final atestados = switch (state) {
                AtestadoLoaded(:final atestados) => atestados,
                AtestadoActionSuccess(:final atestados) => atestados,
                AtestadoError(:final atestados) => atestados,
                _ => <AtestadoModel>[],
              };
              pendingAtestados.addAll(
                atestados.where((a) => a.status == AtestadoStatus.pending),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                if (_isAdmin && pendingAtestados.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Atestados pendentes',
                          style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...pendingAtestados.map(
                    (atestado) => _AdminAtestadoCard(atestado: atestado),
                  ),
                  const SizedBox(height: 24),
                ],
                const _SectionLabel(label: 'Duração do afastamento'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Data início',
                        value: _dataInicio != null
                            ? _fmt.format(_dataInicio!)
                            : null,
                        onTap: () => _pickDate(isInicio: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Data fim',
                        value: _dataFim != null ? _fmt.format(_dataFim!) : null,
                        onTap: () => _pickDate(isInicio: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Comprovante digital (PDF)'),
                const SizedBox(height: 12),
                _FilePickerBox(
                  fileName: _fileName,
                  onPick: _pickPDF,
                  onClear: _clearFile,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: context.palette.border,
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
                          'Confirmar Envio',
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
                    'O arquivo será revisado pela administração.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.palette.textSecondary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminAtestadoCard extends StatelessWidget {
  final AtestadoModel atestado;

  const _AdminAtestadoCard({required this.atestado});

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar atestado'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Motivo (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AtestadoBloc>().add(
                    RejectAtestadoEvent(
                      atestado.id,
                      reason: controller.text.trim().isEmpty
                          ? null
                          : controller.text.trim(),
                    ),
                  );
            },
            child:
                const Text('Recusar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final inicio = fmt.format(DateTime.parse(atestado.dataInicio));
    final fim = fmt.format(DateTime.parse(atestado.dataFim));
    final mesmodia = atestado.dataInicio == atestado.dataFim;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              atestado.employeeName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range_outlined,
                    size: 16, color: context.palette.textSecondary),
                const SizedBox(width: 6),
                Text(
                  mesmodia ? inicio : '$inicio – $fim',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 16, color: context.palette.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    atestado.fileName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.palette.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context
                        .read<AtestadoBloc>()
                        .add(ApproveAtestadoEvent(atestado.id)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w800,
          color: context.palette.textPrimary,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.3)
              : context.palette.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.palette.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: hasValue
                          ? AppColors.primary
                          : context.palette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value ?? 'Clique aqui',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: hasValue
                              ? context.palette.textPrimary
                              : context.palette.textSecondary.withValues(alpha: 0.5),
                          fontWeight:
                              hasValue ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilePickerBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FilePickerBox({
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = fileName != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasFile
            ? AppColors.primary.withValues(alpha: 0.02)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile
              ? AppColors.primary.withValues(alpha: 0.3)
              : context.palette.border,
          style: hasFile
              ? BorderStyle.solid
              : BorderStyle.solid, // Could use dashed if package available
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: hasFile ? null : onPick,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasFile) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('Selecionar PDF', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Clique para buscar no dispositivo',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.palette.textSecondary),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName!,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Documento carregado',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        onPressed: onClear,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
