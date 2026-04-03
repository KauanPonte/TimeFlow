
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
  }) async {
    final pdf = pw.Document();
    final dataTable = [
      ['Data', 'Registros', 'Obs']
    ];

    final ultimoDiaMes =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final hojeApenasData =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (int i = 1; i <= ultimoDiaMes; i++) {
      final date = DateTime(selectedDate.year, selectedDate.month, i);
      if (date.isAfter(hojeApenasData)) continue;
      
      final diaId = DateFormat('yyyy-MM-dd').format(date);
      final registros = punchRecords[diaId];
      
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final holidayName = calendarBlockedDays[diaId];
      final isWorkDay = !isWeekend && holidayName == null;
      final effectiveLoad = isWorkDay ? workloadMinutes : 0;

      final p = processDayDetails(registros ?? [], effectiveLoad, isWorkDay, holidayName);
      dataTable.add(
          [DateFormat('dd/MM').format(date), p["registros"]!, p["obs"]!]);
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Header(
            level: 0,
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Espelho de Ponto - $userName",
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

  static Map<String, String> processDayDetails(List<Map<String, dynamic>> eventos, int expectedLoad, bool isWorkDay, String? holidayName) {
    if (eventos.isEmpty) {
      if (holidayName != null) {
        return {"registros": "-", "obs": holidayName};
      }
      if (!isWorkDay) {
        return {"registros": "-", "obs": "-"};
      }
      return {"registros": "Sem registros", "obs": "Falta"};
    }
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
      if (total > expectedLoad) {
        obs = "Extra: ${formatMinutes(total - expectedLoad)}";
      } else if (total < expectedLoad && total > 0) {
        obs = "Débito: ${formatMinutes(expectedLoad - total)}";
      }
    }
    return {"registros": registros, "obs": obs};
  }
}
