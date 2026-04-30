import 'dart:html' as html;
import 'download_pdf.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateUserHistoryPdf({
    required String userName,
    required DateTime selectedDate,
    required int workloadMinutes, // Per day workload
    required Map<String, List<Map<String, dynamic>>> punchRecords,
    required Map<String, String> calendarBlockedDays,
    Uint8List? assinaturaUsuario,
    Uint8List? assinaturaRH,
  }) async {
    final pdf = pw.Document();
    //final logo =
    //    await imageFromAssetBundle('assets/logoiracema_icon/logo_comprida.png');
    final timbrado =
        await imageFromAssetBundle('assets/timbradologo_icon/timbrado.png');

    final ultimoDiaMes =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    final hojeApenasData =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final dataTable = [
      ['Data', 'Registros', 'Modalidade', 'Observações']
    ];

    for (int i = 1; i <= ultimoDiaMes; i++) {
      final date = DateTime(selectedDate.year, selectedDate.month, i);
      if (date.isAfter(hojeApenasData)) continue;

      final diaId = DateFormat('yyyy-MM-dd').format(date);
      final registros = punchRecords[diaId];

      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final holidayName = calendarBlockedDays[diaId];
      final isWorkDay = !isWeekend && holidayName == null;
      final effectiveLoad = isWorkDay ? workloadMinutes : 0;

      final p = processDayDetails(
          registros ?? [], effectiveLoad, isWorkDay, holidayName);
      dataTable.add([
        DateFormat('dd/MM').format(date),
        p["registros"]!,
        p["modalidade"]!,
        p["obs"]!
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(
            top: 110, // ← espaço para o cabeçalho do timbrado
            bottom: 100, // ← espaço para o rodapé do timbrado
            left: 40,
            right: 40,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(timbrado, fit: pw.BoxFit.fill),
          ),
        ),
        build: (context) => [
          //CABEÇALHO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  //pw.Image(logo, height: 40),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Espelho de Ponto",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    DateFormat('MM/yyyy').format(selectedDate),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 6),
          pw.Container(height: 2, color: PdfColors.green),
          pw.SizedBox(height: 20),

          // BLOCO DE INFO
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F5F5'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Funcionário: $userName",
                    style: pw.TextStyle(fontSize: 9)),
                pw.Text("Carga diária: ${formatMinutes(workloadMinutes)}",
                    style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          //TABELA
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey500,
              width: 1.0,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.9), //data
              1: const pw.FlexColumnWidth(1.5), //registros
              2: const pw.FlexColumnWidth(1.5), //modalidade
              3: const pw.FlexColumnWidth(3.2), //observações
            },
            children: List.generate(dataTable.length, (index) {
              final row = dataTable[index];
              final isHeader = index == 0;

              return pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                decoration: pw.BoxDecoration(
                  color: isHeader
                      ? PdfColor.fromHex('#1B5E20')
                      : (index % 2 == 0
                          ? PdfColor.fromHex('#FAFAFA')
                          : PdfColors.white),
                ),
                children: row.map((cell) {
                  return pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    /*decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top:
                            pw.BorderSide(color: PdfColors.grey500, width: 1.0),
                        bottom:
                            pw.BorderSide(color: PdfColors.grey500, width: 1.0),
                        left:
                            pw.BorderSide(color: PdfColors.grey500, width: 1.0),
                        right:
                            pw.BorderSide(color: PdfColors.grey500, width: 1.0),
                      ),
                    ),*/
                    child: pw.Text(
                      cell,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: isHeader ? PdfColors.white : PdfColors.black,
                        fontWeight: isHeader ? pw.FontWeight.bold : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ),

          pw.SizedBox(height: 40),

          //ASSINATURAS
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              assinaturaComImagem(
                  label: "Colaborador", assinaturaBytes: assinaturaUsuario),
              assinaturaComImagem(
                  label: "Responsável / RH", assinaturaBytes: assinaturaRH),
            ],
          ),

          pw.SizedBox(height: 30),

          // RODAPÉ
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              "Instituto Iracema de Pesquisa e Inovação - Documento gerado automaticamente",
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
    final bytes = await pdf.save();

    final nomeMes = DateFormat('MMMM', 'pt_BR').format(selectedDate);

    final fileName =
        "$userName ${nomeMes[0].toUpperCase()}${nomeMes.substring(1)} ${selectedDate.year}.pdf";

    //await downloadPdf(bytes, fileName);

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  static String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes.toString().padLeft(2, '0')}m";
  }

  static int _calculateTotalMinutes(List<Map<String, dynamic>> eventos) {
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

  static Map<String, String> processDayDetails(
      List<Map<String, dynamic>> eventos,
      int expectedLoad,
      bool isWorkDay,
      String? holidayName) {
    if (eventos.isEmpty) {
      if (holidayName != null) {
        return {"registros": "-", "obs": holidayName, "modalidade": "-"};
      }
      if (!isWorkDay) {
        return {"registros": "-", "obs": "-", "modalidade": "-"};
      }
      return {"registros": "Sem registros", "obs": "Falta", "modalidade": "-"};
    }
    bool isHomeOffice = eventos.any((e) => e['homeOffice'] == true);

    String modalidade = isHomeOffice ? "Home Office" : "Presencial";
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
    }).join('\n\n');

    String obs = "Ok";

    if (eventos.length % 2 != 0) {
      obs = "Incompleto";
    } else {
      final total = _calculateTotalMinutes(eventos);
      if (total > expectedLoad) {
        obs = "Extra: ${formatMinutes(total - expectedLoad)}";
      } else if (total < expectedLoad && total > 0) {
        obs = "Débito: ${formatMinutes(expectedLoad - total)}";
      }
    }
    return {"registros": registros, "obs": obs, "modalidade": modalidade};
  }

  static pw.Widget assinaturaComImagem({
    required String label,
    Uint8List? assinaturaBytes,
  }) {
    pw.ImageProvider? image;

    if (assinaturaBytes != null) {
      image = pw.MemoryImage(assinaturaBytes);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        assinaturaBytes != null
            ? pw.Container(
                height: 60,
                child: pw.Image(image!, fit: pw.BoxFit.contain),
              )
            : pw.Container(
                width: 180,
                height: 1,
                color: PdfColors.black,
              ),
        pw.SizedBox(height: 6),
        pw.Text(label, style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}
