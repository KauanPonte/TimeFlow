import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

class EditUserDialog extends StatefulWidget {
  final String userName;
  final String currentRole;
  final int? currentWorkloadMinutes;
  final String currentContractType;
  final List<String> currentWorkDays;
  final String currentProjectType;
  final List<String> currentProjects;

  final void Function({
    required String role,
    required int workloadMinutes,
    required String contractType,
    required List<String> workDays,
    required String projectType,
    required List<String> projects,
    required DateTime? effectiveDate,
  }) onSave;

  const EditUserDialog({
    super.key,
    required this.userName,
    required this.currentRole,
    required this.currentWorkloadMinutes,
    required this.onSave,
    this.currentContractType = '',
    this.currentWorkDays = const [],
    this.currentProjectType = '',
    this.currentProjects = const [],
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _roleController;
  late final TextEditingController _workloadController;
  late final List<TextEditingController> _projectControllers;

  late String _contractType;
  late String _selectedBolsistaHour;
  late final List<String> _selectedWorkDays;
  late String _projectType;

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
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.currentRole);
    _contractType = widget.currentContractType;
    _selectedWorkDays = List.of(widget.currentWorkDays);
    _projectType = widget.currentProjectType;

    // Carga horária: converte minutos de volta para horas
    final currentHour = _minutesToHourString(widget.currentWorkloadMinutes);
    _workloadController = TextEditingController(text: currentHour);
    _selectedBolsistaHour = ['4', '6', '8'].contains(currentHour)
        ? currentHour
        : '4';

    // Projetos: inicializa com os valores atuais
    final initial = widget.currentProjects.isNotEmpty
        ? widget.currentProjects
        : [''];
    _projectControllers =
        initial.map((p) => TextEditingController(text: p)).toList();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _workloadController.dispose();
    for (final c in _projectControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _minutesToHourString(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h' : '$h:${m.toString().padLeft(2, '0')}';
  }

  int _parseWorkload(String input) {
    input = input.trim();
    if (input.contains(':')) {
      final parts = input.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return (int.tryParse(input) ?? 0) * 60;
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
        if (!['4', '6', '8'].contains(_selectedBolsistaHour)) {
          _selectedBolsistaHour = '4';
        }
        _workloadController.text = _selectedBolsistaHour;
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

  bool _workDaysEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = {...a};
    final sb = {...b};
    return sa.containsAll(sb) && sb.containsAll(sa);
  }

  Future<void> _submit() async {
    var valid = true;
    final role = _roleController.text.trim();

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

    final workloadMinutes = _parseWorkload(_workloadController.text);

    final bool workloadChanged =
        workloadMinutes != (widget.currentWorkloadMinutes ?? 0);
    final bool contractChanged = _contractType != widget.currentContractType;
    final bool daysChanged =
        !_workDaysEqual(_selectedWorkDays, widget.currentWorkDays);

    DateTime? effectiveDate;
    if (workloadChanged || contractChanged || daysChanged) {
      final now = DateTime.now();
      effectiveDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
        helpText: 'A partir de qual data essa mudança entra em vigor?',
        confirmText: 'Confirmar',
        cancelText: 'Cancelar',
      );
      if (effectiveDate == null) return; // admin cancelou
    }

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSave(
      role: role,
      workloadMinutes: workloadMinutes,
      contractType: _contractType,
      workDays: List.unmodifiable(_selectedWorkDays),
      projectType: _projectType,
      projects: _projectControllers.map((c) => c.text).toList(),
      effectiveDate: effectiveDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Editar usuário',
      subtitle: widget.userName,
      icon: Icons.manage_accounts_rounded,
      confirmLabel: 'Salvar',
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
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
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
          _SectionLabel(label: 'Carga horária bolsista'),
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
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                selected: selected,
                onSelected: (_) => _toggleWorkDay(option['value']!),
                selectedColor: const Color(0xFF178573),
                backgroundColor: const Color(0xFF62C1B1),
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
