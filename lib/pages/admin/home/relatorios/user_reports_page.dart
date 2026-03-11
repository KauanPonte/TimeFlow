import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UserReportsPage extends StatefulWidget {
  final String userName;
  final String? profileImageUrl; // Foto vinda da profile page

  const UserReportsPage(
      {super.key, required this.userName, this.profileImageUrl});

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  // Controle de data (Iniciando no mês atual)
  DateTime selectedDate = DateTime.now();

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
          TextButton.icon(
            onPressed: () => _generatePdf(),
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            label: Text('Baixar Pdf',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com Nome e Foto de Perfil
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Lógica para abrir perfil do usuário se necessário
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: widget.profileImageUrl != null
                        ? NetworkImage(widget.profileImageUrl!)
                        : null,
                    child: widget.profileImageUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.primary, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Espelho de ponto de',
                          style: AppTextStyles.bodySmall),
                      Text(widget.userName,
                          style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary, fontSize: 24)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Seletor de Período Mensal
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  helpText: "Selecione o mês do relatório",
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Período: ${selectedDate.month}/${selectedDate.year}',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Resumo de Horas
            _buildInfoRow('Escala de trabalho:', '20 horas/semana'),
            _buildInfoRow('Total:', '72 horas de 120 horas'),
            _buildInfoRow('Horas extras:', '48 horas : 7 dias (4h)'),

            const SizedBox(height: 24),

            // Tabela de Registros
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
                  _buildTableRow('01/03',
                      '04:31 de 04h\nExtra: 31 min\nExtras totais: + 04h'),
                  _buildTableRow('02/03', '08:00 de 08h\nSem extras'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextSpan(
                text: value, style: const TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.bgLight,
      child: Row(
        children: [
          Expanded(
              child: Text('Data',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('Registros',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('Anotações',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(String date, String details) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(date,
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.textPrimary))),
          Expanded(
              child: Text(details,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary))),
          Expanded(
              child: Text('---',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório de Ponto - ${widget.userName}',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Período: ${selectedDate.month}/${selectedDate.year}'),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Tabela de registros
                pw.Table.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  headers: ['Data', 'Registros', 'Anotações'],
                  data: <List<String>>[
                    ['01/03', '04:31 de 04h\nExtra: 31 min', '---'],
                    ['02/03', '08:00 de 08h', '---'],
                  ],
                ),
              ],
            );
          },
        ),
      );

      // O Printing.layoutPdf gerencia a abertura ou download em qualquer plataforma
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'relatorio_${widget.userName}.pdf',
      );
    } catch (e) {
      debugPrint("Erro ao gerar PDF: $e");
    }
  }
}
