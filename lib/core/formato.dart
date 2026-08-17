import 'package:intl/intl.dart';
import '../models/compra_model.dart';

final _formatoLempiras = NumberFormat.currency(locale: 'es_HN', symbol: 'L ', decimalDigits: 2);
final _formatoDolares = NumberFormat.currency(locale: 'en_US', symbol: '\$ ', decimalDigits: 2);
final _formatoFecha = DateFormat('d MMM yyyy', 'es');
final _formatoFechaLarga = DateFormat("d 'de' MMMM 'de' yyyy", 'es');
final _formatoMesAnio = DateFormat('MMMM yyyy', 'es');

String formatearMonto(double monto, Moneda moneda) {
  return moneda == Moneda.usd ? _formatoDolares.format(monto) : _formatoLempiras.format(monto);
}

String formatearLempiras(double monto) => _formatoLempiras.format(monto);

String formatearFecha(DateTime fecha) => _formatoFecha.format(fecha);

String formatearFechaLarga(DateTime fecha) => _formatoFechaLarga.format(fecha);

String formatearMesAnio(DateTime fecha) {
  final texto = _formatoMesAnio.format(fecha);
  return texto[0].toUpperCase() + texto.substring(1);
}
