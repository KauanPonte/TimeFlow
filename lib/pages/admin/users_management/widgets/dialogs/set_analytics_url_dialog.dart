import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class SetAnalyticsUrlDialog extends StatefulWidget {
  const SetAnalyticsUrlDialog({super.key});

  @override
  State<SetAnalyticsUrlDialog> createState() => _SetAnalyticsUrlDialogState();
}

class _SetAnalyticsUrlDialogState extends State<SetAnalyticsUrlDialog> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('analyticsReportUrl') ??
        'https://console.firebase.google.com/project/timeflow-5b4e6/analytics/overview';
    if (!mounted) return;
    _controller.text = current;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analyticsReportUrl', _controller.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('URL do Google Analytics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText:
                  'https://console.firebase.google.com/project/timeflow-5b4e6/analytics/overview',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
