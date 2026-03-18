import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

bool isAdmin = true;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Map<DateTime, List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = _generateMockEvents(_focusedDay.year);
  }

  // --- FUNÇÕES DE LÓGICA ---

  // Função auxiliar para garantir que a data seja sempre Meia-Noite
  // Isso resolve o problema de o funcionário não ver o que o admin salvou
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<DateTime, List<Map<String, dynamic>>> _generateMockEvents(int year) {
    final holidays = getBrazilHolidays(year);
    Map<DateTime, List<Map<String, dynamic>>> data = {};

    holidays.forEach((date, name) {
      data[_normalizeDate(date)] = [
        {'title': name, 'color': Colors.green[400]}
      ];
    });

    final now = DateTime.now();
    data[_normalizeDate(DateTime(now.year, now.month, 11))] = [
      {'title': 'Escritório', 'color': Colors.purple[300]},
      {'title': 'Escritório', 'color': Colors.purple[100]},
    ];
    data[_normalizeDate(DateTime(now.year, now.month, 12))] = [
      {'title': 'Reunião S', 'color': Colors.orange[200]},
    ];

    return data;
  }

  void _confirmDeleteEvent(DateTime date, int index) {
    if (!isAdmin) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Evento?"),
        content: Text(
            "Deseja remover '${_events[date]![index]['title']}' deste dia?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              setState(() {
                _events[date]!.removeAt(index);
                if (_events[date]!.isEmpty) _events.remove(date);
              });
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- UI PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFDDE3F9),
      appBar: AppBar(
        title: const Text('Calendário'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      // O botão só existe na árvore de widgets se isAdmin for true
      floatingActionButton: isAdmin 
          ? FloatingActionButton(
              onPressed: () => _showAddEventDialog(),
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TableCalendar(
                  locale: 'pt_BR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  rowHeight: 100,
                  headerStyle: const HeaderStyle(
                      formatButtonVisible: false, titleCentered: true),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) =>
                        _buildDayCell(day, isDark, false),
                    todayBuilder: (context, day, focusedDay) =>
                        _buildDayCell(day, isDark, true, isToday: true),
                    selectedBuilder: (context, day, focusedDay) =>
                        _buildDayCell(day, isDark, true, isSelected: true),
                    outsideBuilder: (context, day, focusedDay) => Opacity(
                        opacity: 0.3, child: _buildDayCell(day, isDark, false)),
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
  }

  Widget _buildDayCell(DateTime day, bool isDark, bool highlight,
      {bool isToday = false, bool isSelected = false}) {
    // Sincronização: Usa a função de normalizar para buscar os eventos
    final dateOnly = DateTime(day.year, day.month, day.day);
    final events = _events[dateOnly] ?? [];

    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200, width: 0.5),
        color: isSelected
            ? Colors.yellow.withOpacity(0.3)
            : (isToday ? Colors.blue.withOpacity(0.1) : null),
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
                int idx = entry.key;
                var event = entry.value;

                return GestureDetector(
                  onLongPress: () =>
                      isAdmin ? _confirmDeleteEvent(dateOnly, idx) : null,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: event['color'],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      event['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
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

  // --- DIALOGS E COMPONENTES AUXILIARES ---

  void _showAddEventDialog() {
    if (!isAdmin) return;
    final TextEditingController controller = TextEditingController();
    Color selectedColor = Colors.green[400]!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text("Evento para ${DateFormat('dd/MM').format(_selectedDay!)}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration:
                    const InputDecoration(hintText: "Ex: Ponto Facultativo"),
              ),
              const SizedBox(height: 15),
              DropdownButton<Color>(
                value: selectedColor,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                      value: Colors.green[400],
                      child: const Text("Feriado / Facultativo")),
                  DropdownMenuItem(
                      value: Colors.purple[300],
                      child: const Text("Escritório")),
                  DropdownMenuItem(
                      value: Colors.blue[300], child: const Text("Pessoal")),
                ],
                onChanged: (color) =>
                    setDialogState(() => selectedColor = color!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty && _selectedDay != null) {
                  setState(() {
                    // SALVAMENTO: Sempre normaliza antes de guardar no Map
                    final cleanDate = _normalizeDate(_selectedDay!);
                    _events[cleanDate] ??= [];
                    _events[cleanDate]!.add({
                      'title': controller.text,
                      'color': selectedColor,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Adicionar ao Calendário"),
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
          _legendItem("Escritório", Colors.purple[300]!),
          _legendItem("Pessoal", Colors.blue[300]!),
          _legendItem("Reuniões", Colors.orange[300]!),
          _legendItem("Feriados", Colors.green[400]!),
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
                color: color, borderRadius: BorderRadius.circular(2))),
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

    // Cálculos de datas móveis (Páscoa e derivados)
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
