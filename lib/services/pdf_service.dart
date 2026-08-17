import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/cargos.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';

Future<void> exportarEstadoCuentaPdf({
  required TarjetaModel tarjeta,
  required DateTime periodo,
  required List<CargoPendiente> cargos,
  required double tasaUsdHnl,
}) async {
  final doc = pw.Document();

  final totalHnl = cargos
      .where((c) => c.compra.moneda == Moneda.hnl)
      .fold(0.0, (s, c) => s + c.cuota.monto);
  final totalUsd = cargos
      .where((c) => c.compra.moneda == Moneda.usd)
      .fold(0.0, (s, c) => s + c.cuota.monto);
  final totalGeneralHnl = totalHnl + totalUsd * tasaUsdHnl;
  final pagados = cargos.where((c) => c.cuota.pagada).length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Estado de cuenta', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(tarjeta.nombre, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(formatearMesAnio(periodo), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Corte día ${tarjeta.diaCorte} · Pago día ${tarjeta.diaPago}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
            4: pw.FlexColumnWidth(1.3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _celda('Descripción', negrita: true),
                _celda('Detalle', negrita: true),
                _celda('Monto', negrita: true),
                _celda('Vence', negrita: true),
                _celda('Estado', negrita: true),
              ],
            ),
            ...cargos.map((c) {
              final etiqueta = c.cuota.esComision ? 'Comisión inicial' : 'Cuota ${c.cuota.numero} de ${c.compra.numCuotas}';
              return pw.TableRow(
                children: [
                  _celda(c.compra.descripcion),
                  _celda(etiqueta),
                  _celda(formatearMonto(c.cuota.monto, c.compra.moneda)),
                  _celda(formatearFecha(c.cuota.fechaVencimiento)),
                  _celda(c.cuota.pagada ? 'Pagada' : 'Pendiente'),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (totalUsd > 0) pw.Text('Total en dólares: ${formatearMonto(totalUsd, Moneda.usd)}'),
              if (totalHnl > 0) pw.Text('Total en lempiras: ${formatearMonto(totalHnl, Moneda.hnl)}'),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total del período (equivalente en L): ${formatearLempiras(totalGeneralHnl)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text('Tasa usada: 1 USD = ${formatearLempiras(tasaUsdHnl)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('$pagados de ${cargos.length} cargos ya pagados', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'estado_cuenta_${tarjeta.nombre.replaceAll(' ', '_')}_${periodo.year}_${periodo.month}.pdf',
  );
}

pw.Widget _celda(String texto, {bool negrita = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(texto, style: pw.TextStyle(fontSize: 9.5, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );
}
