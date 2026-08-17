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
  required List<Cargo> cargos,
  required double tasaUsdHnl,
}) async {
  final doc = pw.Document();

  double enLempiras(Cargo c) => c.moneda == Moneda.usd ? c.monto * tasaUsdHnl : c.monto;

  final totalGeneral = cargos.fold<double>(0.0, (s, c) => s + enLempiras(c));
  final totalPagado = cargos.where((c) => c.pagada).fold<double>(0.0, (s, c) => s + enLempiras(c));
  final totalPendiente = cargos.where((c) => !c.pagada).fold<double>(0.0, (s, c) => s + enLempiras(c));
  final pagados = cargos.where((c) => c.pagada).length;

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
              return pw.TableRow(
                children: [
                  _celda(c.descripcion),
                  _celda(c.etiqueta),
                  _celda(formatearMonto(c.monto, c.moneda)),
                  _celda(formatearFecha(c.fechaVencimiento)),
                  _celda(
                    c.pagada ? 'Pagada' : 'Pendiente',
                    color: c.pagada ? PdfColors.green700 : PdfColors.orange800,
                    negrita: true,
                  ),
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
              _filaResumen('Total del período', formatearLempiras(totalGeneral), negrita: true),
              pw.SizedBox(height: 3),
              _filaResumen('Ya pagado', formatearLempiras(totalPagado), color: PdfColors.green700),
              pw.SizedBox(height: 3),
              _filaResumen('Pendiente de pagar', formatearLempiras(totalPendiente), color: PdfColors.orange800),
              pw.SizedBox(height: 8),
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

pw.Widget _filaResumen(String etiqueta, String valor, {bool negrita = false, PdfColor? color}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(etiqueta, style: pw.TextStyle(fontSize: negrita ? 13 : 11, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
      pw.Text(
        valor,
        style: pw.TextStyle(fontSize: negrita ? 15 : 12, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black),
      ),
    ],
  );
}

pw.Widget _celda(String texto, {bool negrita = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      texto,
      style: pw.TextStyle(fontSize: 9.5, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black),
    ),
  );
}
