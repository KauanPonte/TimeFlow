import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

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
    _events = _generateMockEvents(_focusedDay.year);
  }

  // Simulação de eventos e feriados (incluindo regionais)
  Map<DateTime, List<Map<String, dynamic>>> _generateMockEvents(int year) {
    final holidays = getBrazilHolidays(year);
    Map<DateTime, List<Map<String, dynamic>>> data = {};

    holidays.forEach((date, name) {
      data[date] = [
        {'title': name, 'color': Colors.green[400]}
      ];
    });

    // Exemplo de eventos fixos para teste (conforme sua legenda)
    final now = DateTime.now();
    data[DateTime(now.year, now.month, 11)] = [
      {'title': 'Escritório', 'color': Colors.purple[300]},
      {'title': 'Escritório', 'color': Colors.purple[100]},
    ];
    data[DateTime(now.year, now.month, 12)] = [
      {'title': 'Reunião S', 'color': Colors.orange[200]},
    ];

    return data;
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: Colors.blue[300],
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                  rowHeight: 100, // Altura maior para caber os textos
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  // BUILDER PERSONALIZADO PARA OS QUADRADINHOS
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

  // Função que desenha cada célula (quadradinho) do calendário
  Widget _buildDayCell(DateTime day, bool isDark, bool highlight,
      {bool isToday = false, bool isSelected = false}) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final events = _events[dateOnly] ?? [];

    return Container(
      margin:
          const EdgeInsets.all(0.5), // Cria o efeito de grade (bordas finas)
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200, width: 0.5),
        color: isSelected
            ? Colors.blue.withOpacity(0.1)
            : (isToday ? Colors.yellow.withOpacity(0.1) : null),
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
          // Renderiza os textos dos eventos dentro do quadrado
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: events
                  .map((event) => Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 1, horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
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
                      ))
                  .toList(),
            ),
          ),
        ],
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

    // Cálculo da Páscoa (Algoritmo de Meeus/Jones/Butcher) calendário gregoriano
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

    // ---  feriados do Ceará ---
    holidays[DateTime(year, 3, 19)] = "São José (CE)";
    holidays[DateTime(year, 3, 25)] = "Data Magna (CE)";

    return holidays;
  }

  void _showAddEventDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialogScaffold(
          title: 'Novo Evento Pessoal',
          icon: Icons.event,
          confirmLabel: 'Salvar',
          onConfirm: () {
            if (controller.text.isNotEmpty && _selectedDay != null) {
              setState(() {
                final date = DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day);
                _events[date] ??= [];
                _events[date]!.add({
                  'title': controller.text,
                  'color': Colors.blue[300]
                });
              });
              Navigator.pop(context);
            }
          },
          children: [
            AppDialogField(
              label: 'Nome do evento',
              hintText: 'Digite o nome do evento',
              controller: controller,
              errorText: null,
              icon: Icons.edit,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }
}
