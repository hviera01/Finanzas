import '../models/compra_model.dart';
import '../models/cuota_model.dart';

/// Un cargo (comisión o cuota) junto con la compra a la que pertenece —
/// vista aplanada útil para el dashboard y el estado de cuenta.
class CargoPendiente {
  final CompraModel compra;
  final CuotaModel cuota;

  const CargoPendiente(this.compra, this.cuota);
}

List<CargoPendiente> aplanarCargos(List<CompraModel> compras) {
  return compras.expand((c) => c.cuotas.map((q) => CargoPendiente(c, q))).toList();
}

/// Agrupa cargos de una misma tarjeta que vencen el mismo mes (comparten
/// fecha de pago real, ya que el día de pago de la tarjeta es fijo).
class GrupoPago {
  final String tarjetaId;
  final DateTime fecha;
  final List<CargoPendiente> cargos;

  const GrupoPago({required this.tarjetaId, required this.fecha, required this.cargos});

  double totalPorMoneda(Moneda moneda) {
    return cargos
        .where((c) => c.compra.moneda == moneda)
        .fold(0.0, (s, c) => s + c.cuota.monto);
  }

  double totalEnLempiras(double tasaUsdHnl) {
    return totalPorMoneda(Moneda.hnl) + totalPorMoneda(Moneda.usd) * tasaUsdHnl;
  }
}

List<GrupoPago> agruparPorPago(List<CargoPendiente> cargos) {
  final grupos = <String, List<CargoPendiente>>{};
  for (final c in cargos) {
    final f = c.cuota.fechaVencimiento;
    final key = '${c.compra.tarjetaId}_${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    grupos.putIfAbsent(key, () => []).add(c);
  }
  final lista = grupos.entries.map((e) {
    final primero = e.value.first;
    return GrupoPago(
      tarjetaId: primero.compra.tarjetaId,
      fecha: primero.cuota.fechaVencimiento,
      cargos: e.value,
    );
  }).toList();
  lista.sort((a, b) => a.fecha.compareTo(b.fecha));
  return lista;
}
