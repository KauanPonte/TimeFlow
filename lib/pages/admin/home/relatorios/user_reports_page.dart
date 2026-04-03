import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_application_appdeponto/pages/home_page/pages/calendar_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UserReportsPage extends StatefulWidget {
  final String userName;
  final String? profileImageUrl;
  final String userId;
  final int jornadaFixa;

  const UserReportsPage({
    super.key,
    required this.userName,
    required this.userId,
    this.profileImageUrl,
    required this.jornadaFixa,
  });

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  final PontoHistoryRepository _pontoRepo = PontoHistoryRepository();
  final CalendarService _calendarService = CalendarService();

  // Controller e Máscara para o CustomTextField
  final TextEditingController _periodoController = TextEditingController();
  final monthMaskFormatter =
      MaskTextInputFormatter(mask: '##/####', filter: {"#": RegExp(r'[0-9]')});

  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> punchRecords = {};
  bool isLoading = true;
  List<String> holidayDayIds = [];

  int _saldoMinutosMes = 0;
  int _cargaHorariaDinamicaMinutos = 0;
  String _totalHorasMes = "0h 00m";
  String _totalExtrasMes = "0h 00m";

  int get _jornadaDiariaMinutos => widget.jornadaFixa;
  int get _jornadaDiariaHoras => _jornadaDiariaMinutos ~/ 60;

  @override
  void initState() {
    super.initState();
    // Inicia com o mês/ano atual
    _periodoController.text = DateFormat('MM/yyyy').format(selectedDate);
    _loadPunches();
  }

  Future<void> _loadPunches() async {
    setState(() => isLoading = true);
    try {
      final data = await _pontoRepo.loadDaysByMonth(
        uid: widget.userId,
        year: selectedDate.year,
        month: selectedDate.month,
      );

      final resumoMensal = await PontoService.calcularResumoMensal(widget.userId, selectedDate);
      final folgas = await _calendarService.getDaysThatReduceWorkload(
          selectedDate.year, selectedDate.month);

      setState(() {
        punchRecords = data;
        _saldoMinutosMes = resumoMensal.monthBalance.toInt();
        _cargaHorariaDinamicaMinutos = resumoMensal.expectedMinutes;
        holidayDayIds = folgas;
        _actualizeDisplayValues(resumoMensal.workedMinutes);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
      setState(() => isLoading = false);
    }
  }



  void _actualizeDisplayValues(int totalTrabalhado) {
    setState(() {
      _totalHorasMes = _formatMinutes(totalTrabalhado);
      String prefixo = _saldoMinutosMes >= 0 ? "+" : "-";
      _totalExtrasMes = _saldoMinutosMes == 0
          ? "0h 00m"
          : "$prefixo ${_formatMinutes(_saldoMinutosMes.abs())}";
    });
  }

  int _calculateTotalMinutes(List<Map<String, dynamic>> eventos) {
    int total = 0;
    for (int i = 0; i < eventos.length - 1; i += 2) {
      DateTime? inicio = eventos[i]['at'];
      DateTime? fim = eventos[i + 1]['at'];
      if (inicio != null && fim != null) {
        total += fim.difference(inicio).inMinutes;
      }
    }
    return total;
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes.toString().padLeft(2, '0')}m";
  }

  Map<String, String> _processDayDetails(List<Map<String, dynamic>> eventos) {
    if (eventos.isEmpty) return {"registros": "Sem registros", "obs": "Falta"};
    String registros = eventos.map((e) {
      final DateTime? at = e['at'];
      String tipo = (e['tipo'] ?? e['type'] ?? '').toString().toUpperCase();
      String label = tipo.startsWith('E')
          ? 'Entrada'
          : tipo.startsWith('P')
              ? 'Pausa'
              : tipo.startsWith('R')
                  ? 'Retorno'
                  : 'Saída';
      return at != null ? "${DateFormat('HH:mm').format(at)} ($label)" : '';
    }).join('\n');

    String obs = "Ok";
    if (eventos.length % 2 != 0) {
      obs = "Incompleto";
    } else {
      final total = _calculateTotalMinutes(eventos);
      if (total > _jornadaDiariaMinutos) {
        obs = "Extra: ${_formatMinutes(total - _jornadaDiariaMinutos)}";
      } else if (total < _jornadaDiariaMinutos && total > 0)
        // ignore: curly_braces_in_flow_control_structures
        obs = "Débito: ${_formatMinutes(_jornadaDiariaMinutos - total)}";
    }
    return {"registros": registros, "obs": obs};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Relatórios',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          IconButton(
              onPressed: _generatePdf,
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildSummaryStats(),
                  const SizedBox(height: 24),
                  _buildRecordsTable(),
                ],
              ),
            ),
    );
  }

  // --- MÉTODOS DE COMPONENTES DE UI ---

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: widget.profileImageUrl != null
              ? NetworkImage(widget.profileImageUrl!)
              : null,
          child: widget.profileImageUrl == null
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Espelho de ponto de', style: AppTextStyles.bodySmall),
            Text(widget.userName,
                style: AppTextStyles.h2
                    .copyWith(color: AppColors.primary, fontSize: 22)),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 1. O SEU DESIGN ORIGINAL (O que aparece na tela)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Período: ${DateFormat('MM/yyyy').format(selectedDate)}',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            ],
          ),
        ),

        // 2. CAMADA DE INTERAÇÃO (Invisível)
        Positioned.fill(
          child: GestureDetector(
            // TOQUE SIMPLES: Abre o teclado para digitar
            onTap: () {
              _showEditPeriodDialog();
            },
            // TOQUE LONGO: Abre o calendário visual direto
            onLongPress: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                  _periodoController.text =
                      DateFormat('MM/yyyy').format(picked);
                });
                _loadPunches();
              }
            },
          ),
        ),
      ],
    );
  }

// 3. FUNÇÃO PARA EDITAR VIA TECLADO (Mantendo a estética)
  void _showEditPeriodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alterar Período"),
        content: TextField(
          controller: _periodoController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [monthMaskFormatter],
          decoration: const InputDecoration(
            hintText: "MM/AAAA",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_periodoController.text.length == 7) {
                try {
                  final date = DateFormat('MM/yyyy')
                      .parseStrict(_periodoController.text);
                  setState(() => selectedDate = date);
                  _loadPunches();
                  Navigator.pop(context);
                } catch (e) {
                  // Data inválida
                }
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow("Escala:", "$_jornadaDiariaHoras" "h diárias"),
        _statRow("Total no mês:",
            "$_totalHorasMes de ${_formatMinutes(_cargaHorariaDinamicaMinutos)}"),
        _statRow("Saldo Atual:", _totalExtrasMes),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(TextSpan(
        text: '$label ',
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        children: [
          TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.normal))
        ],
      )),
    );
  }

  Widget _buildRecordsTable() {
    final List<Widget> rows = [];
    final ultimoDiaMes =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final hojeApenasData =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (int i = ultimoDiaMes; i >= 1; i--) {
      final date = DateTime(selectedDate.year, selectedDate.month, i);
      if (date.isAfter(hojeApenasData)) continue;

      final diaId = DateFormat('yyyy-MM-dd').format(date);
      final displayDate = DateFormat('dd/MM').format(date);
      final registros = punchRecords[diaId];
      final isFolga = holidayDayIds.contains(diaId);
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      if (registros != null) {
        final p = _processDayDetails(registros);
        rows.add(_buildTableRow(displayDate, p["registros"]!, p["obs"]!));
      } else if (isFolga) {
        rows.add(_buildTableRow(displayDate, "---", "Feriado/Recesso"));
      } else if (!isWeekend) {
        rows.add(_buildTableRow(displayDate, "Sem registros", "Falta"));
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          if (rows.isEmpty)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Nenhum registro encontrado."))
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _buildTableHeader() => const Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text('Data',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 5,
              child: Text('Registros',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Obs',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _buildTableRow(String date, String details, String obs) {
    Color obsColor = obs.contains("Extra")
        ? Colors.green
        : (obs.contains("Feriado") || obs.contains("Recesso"))
            ? Colors.purple
            : (obs.contains("Débito") ||
                    obs.contains("Falta") ||
                    obs.contains("Incompleto"))
                ? Colors.red
                : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child:
                  Text(date, style: AppTextStyles.h3.copyWith(fontSize: 14))),
          Expanded(
              flex: 5, child: Text(details, style: AppTextStyles.bodySmall)),
          Expanded(
              flex: 3,
              child: Text(obs,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: obsColor))),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final dataTable = [
      ['Data', 'Registros', 'Obs']
    ];
    final ultimoDiaMes =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final hojeApenasData =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (int i = ultimoDiaMes; i >= 1; i--) {
      final date = DateTime(selectedDate.year, selectedDate.month, i);
      if (date.isAfter(hojeApenasData)) continue;
      final diaId = DateFormat('yyyy-MM-dd').format(date);
      final registros = punchRecords[diaId];
      if (registros != null) {
        final p = _processDayDetails(registros);
        dataTable.add(
            [DateFormat('dd/MM').format(date), p["registros"]!, p["obs"]!]);
      }
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Header(
            level: 0,
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Espelho de Ponto - ${widget.userName}",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MM/yyyy').format(selectedDate)),
                ])),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          context: context,
          data: dataTable,
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey700),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.topLeft,
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
