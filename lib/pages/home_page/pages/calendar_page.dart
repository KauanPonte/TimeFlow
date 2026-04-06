import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_service.dart';
import 'package:intl/intl.dart' as intl;

// Modelo de opção de evento

class _EventOption {
  final String label;
  final String type;
  final Color color;

  const _EventOption({
    required this.label,
    required this.type,
    required this.color,
  });

  @override
  bool operator ==(Object other) => other is _EventOption && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

// Cores padronizadas dos tipos de evento

class _EventColors {
  _EventColors._();
  static const Color feriado = Color(0xFF43A047);
  static const Color recesso = Color(0xFF00897B);
  static const Color pontoFacultativo = Color(0xFFF57C00);
  static const Color escritorio = Color(0xFF7E57C2);
  static const Color reuniao = Color(0xFFFF8A65);
}

// Página

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isAdmin = false;
  bool _loading = true;

  final CalendarService _calendarService = CalendarService();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _selectedDay = _focusedDay;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            final data = doc.data();
            _isAdmin = (data != null && data['role'] == 'ADM');
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> _generateHolidays(int year) {
    final holidays = getBrazilHolidays(year);
    Map<DateTime, List<Map<String, dynamic>>> data = {};
    holidays.forEach((date, name) {
      data[_normalizeDate(date)] = [
        {'title': name, 'color': _EventColors.feriado, 'isFixed': true}
      ];
    });
    return data;
  }

  bool _blocksRegistration(String type) {
    return ['feriado', 'recesso'].contains(type);
  }

  // Diálogo de exclusão (usa AppDialogScaffold)

  void _confirmDeleteEvent(
    DateTime date,
    int index,
    Map<DateTime, List<Map<String, dynamic>>> eventsMap,
  ) {
    if (!_isAdmin) return;
    final event = eventsMap[date]?[index];
    final docId = event?['id'] as String?;
    if (docId == null) return;

    showDialog(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: 'Excluir Evento?',
        subtitle: "Deseja remover '${event!['title']}' deste dia?",
        icon: Icons.delete_outline,
        isDestructive: true,
        confirmLabel: 'Excluir',
        onConfirm: () async {
          await _calendarService.deleteEvent(docId);
          if (mounted) Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
        children: const [],
      ),
    );
  }

  // Diálogo de adicionar evento (usa AppDialogScaffold)

  void _showAddEventDialog() {
    final TextEditingController controller = TextEditingController();

    final List<_EventOption> options = [
      const _EventOption(
          label: 'Feriado', type: 'feriado', color: _EventColors.feriado),
      const _EventOption(
          label: 'Recesso', type: 'recesso', color: _EventColors.recesso),
      const _EventOption(
          label: 'Ponto Facultativo',
          type: 'ponto_facultativo',
          color: _EventColors.pontoFacultativo),
      const _EventOption(
          label: 'Escritório',
          type: 'escritorio',
          color: _EventColors.escritorio),
      const _EventOption(
          label: 'Reunião', type: 'reuniao', color: _EventColors.reuniao),
    ];

    _EventOption selectedOption = options.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Novo Evento', style: AppTextStyles.h3),
                            Text(
                              intl.DateFormat('dd/MM/yyyy')
                                  .format(_selectedDay!),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(dialogCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 20),

                  // Campo título
                  Text(
                    'Nome do evento',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ex: Natal, Recesso de Janeiro...',
                      hintStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.title,
                          color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tipo do evento
                  Text(
                    'Tipo do evento',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Aviso de bloqueio
                  if (_blocksRegistration(selectedOption.type))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warningLight30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este tipo bloqueia o registro de ponto.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Dropdown
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_EventOption>(
                        value: selectedOption,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(12),
                        items: options.map((opt) {
                          return DropdownMenuItem<_EventOption>(
                            value: opt,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: opt.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(opt.label,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary)),
                                if (_blocksRegistration(opt.type)) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.lock_outline,
                                      size: 12, color: AppColors.warning),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (opt) =>
                            setDialogState(() => selectedOption = opt!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side:
                                const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) {
                              CustomSnackbar.showWarning(
                                  dialogCtx, 'Digite um nome para o evento.');
                              return;
                            }

                            final targetDay = _selectedDay ?? _focusedDay;

                            try {
                              await _calendarService.saveEvent(
                                targetDay,
                                controller.text.trim(),
                                selectedOption.color,
                                selectedOption.type,
                              );
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              if (mounted) {
                                CustomSnackbar.showSuccess(
                                    context, 'Evento salvo com sucesso.');
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                CustomSnackbar.showError(
                                    dialogCtx, 'Erro ao salvar: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<DateTime, List<Map<String, dynamic>>>>(
      stream: _calendarService.getEventsStream(_focusedDay.year),
      builder: (context, snapshot) {
        final holidayEvents = _generateHolidays(_focusedDay.year);
        final dbEvents = snapshot.data ?? {};
        final temporaryEvents =
            Map<DateTime, List<Map<String, dynamic>>>.from(holidayEvents);

        dbEvents.forEach((date, list) {
          final normalized = _normalizeDate(date);

          final filteredList = list.where((evento) {
            if (evento['type'] == 'feriado') return true;
            if (_isAdmin) return true;
            return evento['userId'] == FirebaseAuth.instance.currentUser?.uid;
          }).toList();

          if (temporaryEvents.containsKey(normalized)) {
            temporaryEvents[normalized]!.addAll(filteredList);
          } else if (filteredList.isNotEmpty) {
            temporaryEvents[normalized] = List.from(filteredList);
          }
        });

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendário',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Feriados e eventos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddEventDialog(),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildCalendarCard(temporaryEvents),
                      const SizedBox(height: 16),
                      _buildLegendCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // Calendário

  Widget _buildCalendarCard(
    Map<DateTime, List<Map<String, dynamic>>> eventsMap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime(DateTime.now().year - 10, 1, 1),
        lastDay: DateTime(DateTime.now().year + 10, 12, 31),
        focusedDay: _focusedDay,
        eventLoader: (day) {
          final normalizedDay = _normalizeDate(day);
          return eventsMap[normalizedDay] ?? [];
        },
        calendarFormat: _calendarFormat,
        rowHeight: 60,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon:
              const Icon(Icons.chevron_left, color: AppColors.primary),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) => const SizedBox.shrink(),
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, eventsMap: eventsMap),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, isToday: true, eventsMap: eventsMap),
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, true, isSelected: true, eventsMap: eventsMap),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    bool highlight, {
    bool isToday = false,
    bool isSelected = false,
    required Map<DateTime, List<Map<String, dynamic>>> eventsMap,
  }) {
    final dateOnly = _normalizeDate(day);
    final events = eventsMap[dateOnly] ?? [];

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primaryLight
                  : Colors.transparent,
          width: 1.5,
        ),
        color: isSelected
            ? AppColors.primaryLight10
            : (isToday
                ? AppColors.primaryLight10.withValues(alpha: 0.05)
                : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "${day.day}",
              style: TextStyle(
                fontWeight:
                    isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color:
                    day.weekday == 7 ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: events.asMap().entries.map((entry) {
                final isFixed = entry.value['isFixed'] == true;
                return GestureDetector(
                  onLongPress: isFixed
                      ? () => CustomSnackbar.showInfo(
                          context, 'Este feriado é fixo e não pode ser removido.')
                      : () =>
                          _confirmDeleteEvent(dateOnly, entry.key, eventsMap),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: entry.value['color']
                          .withValues(alpha: isFixed ? 0.75 : 1.0),
                      borderRadius: BorderRadius.circular(4),
                      border: isFixed
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFixed)
                          const Padding(
                            padding: EdgeInsets.only(right: 3),
                            child: Icon(Icons.lock_outline,
                                size: 8, color: Colors.white70),
                          ),
                        Expanded(
                          child: Text(
                            entry.value['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight:
                                  isFixed ? FontWeight.w500 : FontWeight.bold,
                              fontStyle:
                                  isFixed ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Legenda

  Widget _buildLegendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _legendItem('Feriado / Recesso', _EventColors.feriado),
              _legendItem('Ponto Facultativo', _EventColors.pontoFacultativo),
              _legendItem('Escritório', _EventColors.escritorio),
              _legendItem('Reuniões', _EventColors.reuniao),
            ],
          ),
          if (_isAdmin) ...[
            const Divider(height: 24, color: AppColors.borderLight),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Segure pressionado sobre um evento para excluí-lo.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Feriados fixos

  Map<DateTime, String> getBrazilHolidays(int year) {
    Map<DateTime, String> holidays = {
      DateTime(year, 1, 1): "Confraternização Universal",
      DateTime(year, 4, 21): "Tiradentes",
      DateTime(year, 5, 1): "Dia do Trabalho",
      DateTime(year, 9, 7): "Independência do Brasil",
      DateTime(year, 10, 12): "Nossa Senhora Aparecida",
      DateTime(year, 11, 2): "Finados",
      DateTime(year, 11, 15): "Proclamação da República",
      DateTime(year, 11, 20): "Consciência Negra",
      DateTime(year, 12, 25): "Natal",
    };

    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;

    DateTime pascoa = DateTime(year, month, day);

    holidays[pascoa.subtract(const Duration(days: 2))] = "Sexta-feira Santa";
    holidays[pascoa.subtract(const Duration(days: 47))] = "Carnaval";
    holidays[pascoa.add(const Duration(days: 60))] = "Corpus Christi";

    holidays[DateTime(year, 3, 19)] = "São José (CE)";
    holidays[DateTime(year, 3, 25)] = "Data Magna (CE)";

    return holidays;
  }
}
