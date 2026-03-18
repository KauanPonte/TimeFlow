import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_application_appdeponto/repositories/admin_repository.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';

class UserReportsPage extends StatefulWidget {
  final String userName;
  final String? profileImageUrl;
  final String userId;
  final int jornadaHoras;

  const UserReportsPage({
    super.key,
    required this.userName,
    required this.userId,
    this.profileImageUrl,
    this.jornadaHoras = 8,
  });

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  final PontoHistoryRepository _pontoRepo = PontoHistoryRepository();

  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> punchRecords = {};
  bool isLoading = true;

  int _saldoMinutosMes = 0;
  int _trabalhadoMinutosMes = 0;
  String _totalHorasMes = "0h 00m";
  String _totalExtrasMes = "0h 00m";

  int get _jornadaDiariaMinutos => widget.jornadaHoras * 60;

  @override
  void initState() {
    super.initState();
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

      final saldoOficial =
          await PontoService.getSaldoMesPorUsuario(widget.userId, selectedDate);

      setState(() {
        punchRecords = data;
        _saldoMinutosMes = saldoOficial;

        int totalTrabalhado = 0;
        punchRecords.forEach((diaId, eventos) {
          totalTrabalhado += _calculateTotalMinutes(eventos);
        });

        _trabalhadoMinutosMes = totalTrabalhado;
        _totalHorasMes = _formatMinutes(totalTrabalhado);

        String prefixo = _saldoMinutosMes >= 0 ? "+" : "-";
        _totalExtrasMes = "$prefixo ${_formatMinutes(_saldoMinutosMes.abs())}";

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao buscar pontos: $e");
      setState(() => isLoading = false);
    }
  }

  Map<String, String> _processDayDetails(List<Map<String, dynamic>> eventos) {
    if (eventos.isEmpty) return {"registros": "Sem registros", "obs": "Falta"};

    String registros = eventos.map((e) {
      final DateTime? at = e['at'];
      String tipo = (e['tipo'] ?? e['type'] ?? '').toString().toUpperCase();
      if (at == null) return '';

      String label = tipo;
      if (tipo.startsWith('E'))
        label = 'Entrada';
      else if (tipo.startsWith('P'))
        label = 'Pausa';
      else if (tipo.startsWith('R'))
        label = 'Retorno';
      else if (tipo.startsWith('S')) label = 'Saída';

      return "${DateFormat('HH:mm').format(at)} ($label)";
    }).join(' | ');

    String obs = "---";
    if (eventos.length % 2 != 0) {
      obs = "Registro Incompleto";
    } else {
      final totalTrabalhado = _calculateTotalMinutes(eventos);
      if (totalTrabalhado > _jornadaDiariaMinutos) {
        final extra = totalTrabalhado - _jornadaDiariaMinutos;
        obs = "Extra: ${_formatMinutes(extra)}";
      } else if (totalTrabalhado < _jornadaDiariaMinutos &&
          totalTrabalhado > 0) {
        final debito = _jornadaDiariaMinutos - totalTrabalhado;
        obs = "Débito: ${_formatMinutes(debito)}";
      }
    }
    return {"registros": registros, "obs": obs};
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

  // --- WIDGETS DA TELA ---

  @override
  Widget build(BuildContext context) {
    final sortedDayIds = punchRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildSummaryStats(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(height: 1),
                  if (isLoading)
                    const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()))
                  else if (punchRecords.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(40),
                        child:
                            Center(child: Text("Nenhum registro encontrado.")))
                  else
                    ...sortedDayIds.map((diaId) {
                      final processado =
                          _processDayDetails(punchRecords[diaId]!);
                      final displayDate =
                          diaId.split('-').reversed.take(2).join('/');
                      return _buildTableRow(displayDate,
                          processado["registros"]!, processado["obs"]!);
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final String prefixo = _saldoMinutosMes >= 0 ? "+" : "-";
    final String saldoFormatado =
        "$prefixo ${_formatMinutes(_saldoMinutosMes.abs())}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow("Escala de trabalho:", "${widget.jornadaHoras}h diárias"),
        _statRow(
            "Total trabalhado no mês:", _formatMinutes(_trabalhadoMinutosMes)),
        _statRow("Saldo (Banco de Horas):", saldoFormatado),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
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
                    .copyWith(color: AppColors.primary, fontSize: 24)),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
          _loadPunches();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Período: ${DateFormat('MM/yyyy').format(selectedDate)}',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Data',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 5,
              child: Text('Registros',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Observações',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(String date, String details, String obs) {
    final registosList = details.split(' | ');
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
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: registosList
                    .map((r) => Text(r, style: AppTextStyles.bodySmall))
                    .toList(),
              )),
          Expanded(
              flex: 2,
              child: Text(obs,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          (obs.contains("Falta") || obs.contains("Incompleto"))
                              ? Colors.red
                              : AppColors.primary))),
        ],
      ),
    );
  }

  // --- LÓGICA DO PDF ---

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final sortedKeys = punchRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text("Espelho de Ponto - ${widget.userName}",
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Período: ${DateFormat('MM/yyyy').format(selectedDate)}"),
          pw.Text("Escala de trabalho: ${widget.jornadaHoras}h diárias"),
          pw.Text("Total trabalhado no mês: $_totalHorasMes"),
          pw.Text("Saldo (Banco de Horas): $_totalExtrasMes"),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(100),
            },
            children: [
              // Cabeçalho da Tabela
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cellPadding("Data", bold: true),
                  _cellPadding("Registros", bold: true),
                  _cellPadding("Observações", bold: true),
                ],
              ),
              // Linhas de dados (Loop correto)
              ...sortedKeys.map((diaId) {
                final eventos = punchRecords[diaId] ?? [];
                final p = _processDayDetails(eventos);
                final dataFormatada =
                    diaId.split('-').reversed.take(2).join('/');

                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _cellPadding(dataFormatada),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: _formatEventosParaPdf(eventos),
                    ),
                    _cellPadding(p["obs"] ?? ""),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Espelho_Ponto_${widget.userName}.pdf',
    );
  }

  pw.Widget _formatEventosParaPdf(List<Map<String, dynamic>> eventos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: eventos.map((e) {
        final DateTime? at = e['at'];
        if (at == null) return pw.SizedBox();
        final hora = DateFormat('HH:mm').format(at);

        // Verifica se a chave é 'type' ou 'tipo' vindo do banco
        String tipoRaw =
            (e['type'] ?? e['tipo'] ?? '').toString().toUpperCase();
        String label = tipoRaw;
        if (tipoRaw.startsWith('E'))
          label = 'Entrada';
        else if (tipoRaw.startsWith('P'))
          label = 'Pausa';
        else if (tipoRaw.startsWith('R'))
          label = 'Retorno';
        else if (tipoRaw.startsWith('S')) label = 'Saída';

        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child:
              pw.Text("$hora ($label)", style: const pw.TextStyle(fontSize: 9)),
        );
      }).toList(),
    );
  }

  pw.Widget _cellPadding(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
