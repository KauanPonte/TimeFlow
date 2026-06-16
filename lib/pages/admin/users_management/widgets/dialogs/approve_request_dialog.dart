import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

class ApproveRequestDialog extends StatefulWidget {
  final String userName;
  final void Function({
    required String role,
    required String cargaHoraria,
    required String contractType,
    required List<String> workDays,
    required String projectType,
    required List<String> projects,
    required DateTime startDate,
    required bool isAdmin,
  }) onApprove;

  const ApproveRequestDialog({
    super.key,
    required this.userName,
    required this.onApprove,
  });

  @override
  State<ApproveRequestDialog> createState() => _ApproveRequestDialogState();
}

class _ApproveRequestDialogState extends State<ApproveRequestDialog> {
  final _roleController = TextEditingController();
  final _workloadController = TextEditingController();
  final List<TextEditingController> _projectControllers = [
    TextEditingController(),
  ];

  bool _isAdmin = false;
  String _contractType = '';
  String _selectedBolsistaHour = '4';
  final List<String> _selectedWorkDays = [];
  String _projectType = '';
  DateTime _startDate = DateTime.now();

  String? _roleError;
  String? _contractTypeError;
  String? _workDaysError;
  String? _projectTypeError;

  static const _weekDayOptions = [
    {'label': 'D', 'value': 'Dom'},
    {'label': 'S', 'value': 'Seg'},
    {'label': 'T', 'value': 'Ter'},
    {'label': 'Q', 'value': 'Qua'},
    {'label': 'Q', 'value': 'Qui'},
    {'label': 'S', 'value': 'Sex'},
    {'label': 'S', 'value': 'Sab'},
  ];

  @override
  void dispose() {
    _roleController.dispose();
    _workloadController.dispose();
    for (final c in _projectControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setContractType(String type) {
    setState(() {
      _contractType = type;
      _contractTypeError = null;
      if (type == 'CLT') {
        _workloadController.text = '8';
        _selectedWorkDays.clear();
        _projectType = '';
        for (final c in _projectControllers) {
          c.dispose();
        }
        _projectControllers
          ..clear()
          ..add(TextEditingController());
      } else {
        _workloadController.text = '4';
        _selectedBolsistaHour = '4';
      }
    });
  }

  void _toggleWorkDay(String day) {
    setState(() {
      if (_selectedWorkDays.contains(day)) {
        _selectedWorkDays.remove(day);
      } else {
        _selectedWorkDays.add(day);
      }
      if (_selectedWorkDays.length >= 3) _workDaysError = null;
    });
  }

  void _submit() {
    var valid = true;
    final role = _roleController.text.trim();
    final workload = _workloadController.text.trim();

    if (role.isEmpty) {
      _roleError = 'Informe o cargo';
      valid = false;
    } else {
      _roleError = null;
    }

    if (_contractType.isEmpty) {
      _contractTypeError = 'Selecione o tipo de contrato';
      valid = false;
    } else {
      _contractTypeError = null;
    }

    if (_contractType == 'Bolsista') {
      if (_selectedWorkDays.length < 3) {
        _workDaysError = 'Selecione ao menos 3 dias';
        valid = false;
      } else {
        _workDaysError = null;
      }
      if (_projectType.isEmpty) {
        _projectTypeError = 'Selecione LAPADA ou IRACEMA';
        valid = false;
      } else {
        _projectTypeError = null;
      }
    }

    if (!valid) {
      setState(() {});
      return;
    }

    final cargaHoraria =
        _contractType == 'Bolsista' ? _selectedBolsistaHour : workload;

    Navigator.pop(context);
    widget.onApprove(
      role: role,
      cargaHoraria: cargaHoraria,
      contractType: _contractType,
      workDays: List.unmodifiable(_selectedWorkDays),
      projectType: _projectType,
      projects: _projectControllers.map((c) => c.text).toList(),
      startDate: _startDate,
      isAdmin: _isAdmin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Aprovar usuário',
      subtitle: widget.userName,
      icon: Icons.check_circle,
      confirmLabel: 'Aprovar',
      onConfirm: _submit,
      children: [
        AppDialogField(
          label: 'Cargo',
          hintText: 'Ex: Funcionário, Gerente, Administrador',
          controller: _roleController,
          errorText: _roleError,
          icon: Icons.badge_outlined,
          autofocus: true,
          onChanged: (_) {
            if (_roleError != null) setState(() => _roleError = null);
          },
        ),
        const SizedBox(height: 16),
        const _SectionLabel(label: 'Nível de Acesso'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: !_isAdmin
                      ? const Color(0xFF178573)
                      : const Color(0xFF62C1B1),
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                ),
                onPressed: () => setState(() => _isAdmin = false),
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(
                  'Usuário',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: !_isAdmin ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isAdmin
                      ? const Color(0xFF178573)
                      : const Color(0xFF62C1B1),
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                ),
                onPressed: () => setState(() => _isAdmin = true),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Administrador',
                    maxLines: 1,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: _isAdmin ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: 'Tipo de Contrato', error: _contractTypeError),
        const SizedBox(height: 8),
        Row(
          children: ['CLT', 'Bolsista'].map((type) {
            final selected = _contractType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? const Color(0xFF178573)
                        : const Color(0xFF62C1B1),
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                  onPressed: () => _setContractType(type),
                  child: Text(
                    type,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_contractType == 'CLT') ...[
          const SizedBox(height: 16),
          IgnorePointer(
            child: AppDialogField(
              label: 'Carga horária diária',
              hintText: 'Ex: 8 ou 8:30',
              controller: _workloadController,
              errorText: null,
              icon: Icons.schedule_rounded,
            ),
          ),
        ],
        if (_contractType == 'Bolsista') ...[
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Carga horária bolsista'),
          const SizedBox(height: 8),
          Row(
            children: ['4 hrs', '6 hrs', '8 hrs'].map((label) {
              final value = label.replaceAll(' hrs', '');
              final selected = _selectedBolsistaHour == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected
                          ? const Color(0xFF178573)
                          : const Color(0xFF62C1B1),
                      foregroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedBolsistaHour = value;
                        _workloadController.text = value;
                      });
                    },
                    child: Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SectionLabel(label: 'Dias de trabalho', error: _workDaysError),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDayOptions.map((option) {
              final selected = _selectedWorkDays.contains(option['value']);
              return ChoiceChip(
                label: Text(
                  option['label']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                selected: selected,
                onSelected: (_) => _toggleWorkDay(option['value']!),
                selectedColor: const Color(0xFF178573),
                backgroundColor: const Color(0xFF62C1B1),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : selected
                          ? const Color(0xFF178573)
                          : const Color(0xFF62C1B1),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SectionLabel(label: 'Projetos', error: _projectTypeError),
          const SizedBox(height: 8),
          Row(
            children: ['LAPADA', 'IRACEMA'].map((type) {
              final selected = _projectType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected
                          ? const Color(0xFF178573)
                          : const Color(0xFF62C1B1),
                      foregroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      setState(() {
                        _projectType = type;
                        _projectTypeError = null;
                      });
                    },
                    child: Text(
                      type,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          ..._projectControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppDialogField(
                      label: 'Projeto ${index + 1}',
                      hintText: 'Nome do projeto',
                      controller: controller,
                      errorText: null,
                      icon: Icons.work_outline,
                    ),
                  ),
                  if (_projectControllers.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          controller.dispose();
                          _projectControllers.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.redAccent,
                      tooltip: 'Remover projeto',
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _projectControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar projeto'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF178573),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 2),
              confirmText: 'Confirmar',
              cancelText: 'Cancelar',
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Data de início',
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_startDate),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? error;

  const _SectionLabel({required this.label, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
}
