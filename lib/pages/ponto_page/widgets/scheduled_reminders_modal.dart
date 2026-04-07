import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/scheduled_reminder.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_dialog_components.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/time_picker.dart';

/// Modal para gerenciar lembretes agendados por categoria.
class ScheduledRemindersModal extends StatefulWidget {
  const ScheduledRemindersModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScheduledRemindersModal(),
    );
  }

  @override
  State<ScheduledRemindersModal> createState() =>
      _ScheduledRemindersModalState();
}

class _ScheduledRemindersModalState extends State<ScheduledRemindersModal> {
  List<ScheduledReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await NotificationService.getScheduledReminders();
      if (!mounted) return;
      setState(() {
        _reminders = List.from(reminders);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addReminder() async {
    final result = await _showAddEditDialog(context);
    if (result == null || !mounted) return;

    final newReminder = ScheduledReminder(
      id: const Uuid().v4(),
      category: result.category,
      hour: result.time.hour,
      minute: result.time.minute,
      enabled: true,
      label: result.label,
    );

    setState(() => _reminders.add(newReminder));

    try {
      await NotificationService.addScheduledReminder(newReminder);
      if (!mounted) return;
      CustomSnackbar.showSuccess(
        context,
        'Lembrete de ${newReminder.category.label} às ${newReminder.formattedTime} adicionado.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminders.removeWhere((r) => r.id == newReminder.id));
      CustomSnackbar.showError(context, 'Erro ao adicionar lembrete.');
    }
  }

  Future<void> _editReminder(ScheduledReminder reminder) async {
    final result = await _showAddEditDialog(
      context,
      existing: reminder,
    );
    if (result == null || !mounted) return;

    final updated = reminder.copyWith(
      category: result.category,
      hour: result.time.hour,
      minute: result.time.minute,
      label: result.label,
    );

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    final previous = _reminders[index];
    setState(() => _reminders[index] = updated);

    try {
      await NotificationService.updateScheduledReminder(updated);
      if (!mounted) return;
      CustomSnackbar.showSuccess(context, 'Lembrete atualizado.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminders[index] = previous);
      CustomSnackbar.showError(context, 'Erro ao atualizar lembrete.');
    }
  }

  Future<void> _deleteReminder(ScheduledReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: 'Excluir Lembrete',
        subtitle: 'Confirmação de remoção',
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
        confirmLabel: 'Excluir',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
        children: [
          Text(
            'Deseja remover o lembrete de ${reminder.category.label} às ${reminder.formattedTime}?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    final removed = _reminders[index];
    setState(() => _reminders.removeAt(index));

    try {
      await NotificationService.removeScheduledReminder(reminder.id);
      if (!mounted) return;
      CustomSnackbar.showSuccess(context, 'Lembrete removido.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminders.insert(index, removed));
      CustomSnackbar.showError(context, 'Erro ao remover lembrete.');
    }
  }

  Future<void> _toggleReminder(ScheduledReminder reminder, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    final previous = _reminders[index];
    setState(() => _reminders[index] = reminder.copyWith(enabled: enabled));

    try {
      await NotificationService.toggleScheduledReminder(
        reminder.id,
        enabled: enabled,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminders[index] = previous);
      CustomSnackbar.showError(context, 'Erro ao atualizar lembrete.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1),
          Flexible(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reminders.isEmpty
                    ? _buildEmptyState()
                    : _buildRemindersList(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPadding),
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembretes Agendados',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_reminders.where((r) => r.enabled).length} ativo(s)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alarm_off_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum lembrete agendado',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione lembretes para ser notificado\nnos horários de entrada, pausa, volta ou saída.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    // Agrupa por categoria
    final grouped = <ReminderCategory, List<ScheduledReminder>>{};
    for (final reminder in _reminders) {
      grouped.putIfAbsent(reminder.category, () => []).add(reminder);
    }

    // Ordena cada grupo por horário
    for (final list in grouped.values) {
      list.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final category in ReminderCategory.values)
          if (grouped.containsKey(category)) ...[
            _buildCategoryHeader(category),
            ...grouped[category]!.map(_buildReminderTile),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildCategoryHeader(ReminderCategory category) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(category.icon, size: 18, color: category.color),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(ScheduledReminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: reminder.enabled
            ? reminder.category.color.withValues(alpha: 0.08)
            : AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.enabled
              ? reminder.category.color.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        leading: Text(
          reminder.formattedTime,
          style: AppTextStyles.h3.copyWith(
            color: reminder.enabled
                ? reminder.category.color
                : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        title: Text(
          reminder.label ?? reminder.category.notificationTitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: reminder.enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: reminder.label != null
            ? Text(
                reminder.category.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: reminder.enabled,
              onChanged: (v) => _toggleReminder(reminder, v),
              activeColor: reminder.category.color,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              offset: const Offset(0, 4),
              onSelected: (value) {
                if (value == 'edit') {
                  _editReminder(reminder);
                } else if (value == 'delete') {
                  _deleteReminder(reminder);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 20, color: AppColors.primary.withValues(alpha: 0.8)),
                      const SizedBox(width: 12),
                      const Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded,
                          size: 20, color: AppColors.error.withValues(alpha: 0.8)),
                      const SizedBox(width: 12),
                      const Text('Excluir',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addReminder,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Adicionar Lembrete'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<_ReminderDialogResult?> _showAddEditDialog(
    BuildContext context, {
    ScheduledReminder? existing,
  }) {
    return showDialog<_ReminderDialogResult>(
      context: context,
      builder: (_) => _AddEditReminderDialog(existing: existing),
    );
  }
}

class _ReminderDialogResult {
  final ReminderCategory category;
  final TimeOfDay time;
  final String? label;

  const _ReminderDialogResult({
    required this.category,
    required this.time,
    this.label,
  });
}

class _AddEditReminderDialog extends StatefulWidget {
  final ScheduledReminder? existing;

  const _AddEditReminderDialog({this.existing});

  @override
  State<_AddEditReminderDialog> createState() => _AddEditReminderDialogState();
}

class _AddEditReminderDialogState extends State<_AddEditReminderDialog> {
  late ReminderCategory _category;
  late TimeOfDay _time;
  final _labelController = TextEditingController();

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? ReminderCategory.entrada;
    _time = widget.existing?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _labelController.text = widget.existing?.label ?? '';
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker24h(context, _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    final label = _labelController.text.trim();
    Navigator.pop(
      context,
      _ReminderDialogResult(
        category: _category,
        time: _time,
        label: label.isEmpty ? null : label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: isEditing ? 'Editar Lembrete' : 'Novo Lembrete',
      subtitle: isEditing
          ? 'Atualize as configurações do lembrete'
          : 'Configure uma nova notificação',
      icon: isEditing ? Icons.edit_notifications_rounded : Icons.add_alarm_rounded,
      confirmLabel: isEditing ? 'Salvar' : 'Adicionar',
      onConfirm: _save,
      children: [
        // Seletor de categoria
        Text(
          'Categoria',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReminderCategory.values.map((cat) {
            final isSelected = _category == cat;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  const SizedBox(width: 4),
                  Text(cat.label, style: const TextStyle(fontSize: 12)),
                ],
              ),
              selected: isSelected,
              selectedColor: cat.color,
              backgroundColor: cat.color.withValues(alpha: 0.1),
              side: BorderSide(
                color: isSelected ? cat.color : AppColors.borderLight,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : cat.color,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _category = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Seletor de horário
        Text(
          'Horário',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _category.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _category.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time_rounded, color: _category.color, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.h2.copyWith(
                    color: _category.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Label personalizado
        AppDialogField(
          label: 'Mensagem personalizada (opcional)',
          hintText: _category.notificationTitle,
          controller: _labelController,
          errorText: null,
          icon: Icons.chat_bubble_outline_rounded,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
