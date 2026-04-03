import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_service.dart';
import 'package:intl/intl.dart' as intl;

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
        {'title': name, 'color': Colors.green[400]}
      ];
    });
    return data;
  }

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
      builder: (context) => AlertDialog(
        title: const Text("Excluir Evento?"),
        content: Text("Deseja remover '${event!['title']}' deste dia?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await _calendarService.deleteEvent(docId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _blocksRegistration(String type) {
    return ['feriado', 'recesso'].contains(type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFDDE3F9),
          appBar: AppBar(
            title: const Text('Calendário'),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          floatingActionButton: _isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddEventDialog(),
                  backgroundColor: Colors.blue[300],
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TableCalendar(
                            locale: 'pt_BR',
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            eventLoader: (day) {
                              final normalizedDay = _normalizeDate(day);
                              return temporaryEvents[normalizedDay] ?? [];
                            },
                            calendarFormat: _calendarFormat,
                            rowHeight: 60,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) =>
                                  const SizedBox.shrink(),
                              defaultBuilder: (context, day, focusedDay) =>
                                  _buildDayCell(day, isDark, false,
                                      eventsMap: temporaryEvents),
                              todayBuilder: (context, day, focusedDay) =>
                                  _buildDayCell(day, isDark, true,
                                      isToday: true,
                                      eventsMap: temporaryEvents),
                              selectedBuilder: (context, day, focusedDay) =>
                                  _buildDayCell(day, isDark, true,
                                      isSelected: true,
                                      eventsMap: temporaryEvents),
                            ),
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLegendBox(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime day,
    bool isDark,
    bool highlight, {
    bool isToday = false,
    bool isSelected = false,
    required Map<DateTime, List<Map<String, dynamic>>> eventsMap,
  }) {
    final dateOnly = _normalizeDate(day);
    final events = eventsMap[dateOnly] ?? [];

    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 0.5,
        ),
        color: isSelected
            ? Colors.yellow.withValues(alpha: 0.3)
            : (isToday ? Colors.blue.withValues(alpha: 0.1) : null),
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
                color: day.weekday == 7
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: events.asMap().entries.map((entry) {
                return GestureDetector(
                  onLongPress: () =>
                      _confirmDeleteEvent(dateOnly, entry.key, eventsMap),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: entry.value['color'],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      entry.value['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showAddEventDialog() {
    final TextEditingController controller = TextEditingController();

    final List<_EventOption> options = [
      _EventOption(
        label: 'Feriado',
        type: 'feriado',
        color: Colors.green[600]!,
      ),
      _EventOption(
        label: 'Recesso',
        type: 'recesso',
        color: Colors.teal[400]!,
      ),
      _EventOption(
        label: 'Ponto Facultativo',
        type: 'ponto_facultativo',
        color: Colors.orange[700]!,
      ),
      _EventOption(
        label: 'Escritório',
        type: 'escritorio',
        color: Colors.purple[300]!,
      ),
      _EventOption(
        label: 'Reunião',
        type: 'reuniao',
        color: Colors.orange[300]!,
      ),
    ];

    _EventOption selectedOption = options.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Novo Evento: ${intl.DateFormat('dd/MM/yyyy').format(_selectedDay!)}",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Ex: Natal, Recesso de Janeiro...",
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipo do evento',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (_blocksRegistration(selectedOption.type))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 14, color: Colors.orange[800]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Este tipo bloqueia o registro de ponto.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              DropdownButton<_EventOption>(
                value: selectedOption,
                isExpanded: true,
                items: options.map((opt) {
                  return DropdownMenuItem<_EventOption>(
                    value: opt,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: opt.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(opt.label),
                        if (_blocksRegistration(opt.type)) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_outline,
                              size: 12, color: Colors.orange[700]),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (opt) => setDialogState(() => selectedOption = opt!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Digite um nome para o evento.'),
                    ),
                  );
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
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao salvar: $e')),
                    );
                  }
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBox(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 15,
        runSpacing: 10,
        children: [
          _legendItem("Feriado / Recesso", Colors.green[600]!),
          _legendItem("Ponto Facultativo", Colors.orange[700]!),
          _legendItem("Escritório", Colors.purple[300]!),
          _legendItem("Reuniões", Colors.orange[300]!),
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

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
