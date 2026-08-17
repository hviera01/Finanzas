import 'package:intl/intl.dart';
import '../models/compra_model.dart';

// Formato fijo (independiente del locale del navegador): coma de miles,
// punto decimal, símbolo pegado al número — "L.1,200.00" / "$1,200.00".
final _formatoNumero = NumberFormat('#,##0.00', 'en_US');
final _formatoFecha = DateFormat('d MMM yyyy', 'es');
final _formatoFechaLarga = DateFormat("d 'de' MMMM 'de' yyyy", 'es');
final _formatoMesAnio = DateFormat('MMMM yyyy', 'es');

String formatearMonto(double monto, Moneda moneda) {
  return moneda == Moneda.usd ? formatearDolares(monto) : formatearLempiras(monto);
}

String formatearLempiras(double monto) => 'L.${_formatoNumero.format(monto)}';

String formatearDolares(double monto) => '\$${_formatoNumero.format(monto)}';

String formatearFecha(DateTime fecha) => _formatoFecha.format(fecha);

String formatearFechaLarga(DateTime fecha) => _formatoFechaLarga.format(fecha);

String formatearMesAnio(DateTime fecha) {
  final texto = _formatoMesAnio.format(fecha);
  return texto[0].toUpperCase() + texto.substring(1);
}
