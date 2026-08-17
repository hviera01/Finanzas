import 'ciclo_facturacion.dart';
import '../models/compra_model.dart';
import '../models/cuota_model.dart';
import '../models/suscripcion_model.dart';
import '../models/tarjeta_model.dart';

enum TipoCargo { comision, cuota, pagoUnico, suscripcion }

/// Vista unificada de cualquier cosa que haya que pagar en una tarjeta:
/// una comisión o cuota de una compra, un pago único, o el cobro mensual
/// de una suscripción. Útil para el dashboard, el estado de cuenta y el PDF.
class Cargo {
  final String tarjetaId;
  final String descripcion;
  final String etiqueta;
  final double monto;
  final Moneda moneda;
  final DateTime fechaVencimiento;
  final int anio;
  final int mes;
  final bool pagada;
  final DateTime? fechaPago;
  final TipoCargo tipo;

  // Origen del cargo, para poder marcarlo pagado o navegar a su detalle.
  final CompraModel? compra;
  final CuotaModel? cuota;
  final SuscripcionModel? suscripcion;
  final String? periodoKey;

  const Cargo({
    required this.tarjetaId,
    required this.descripcion,
    required this.etiqueta,
    required this.monto,
    required this.moneda,
    required this.fechaVencimiento,
    required this.anio,
    required this.mes,
    required this.pagada,
    required this.fechaPago,
    required this.tipo,
    this.compra,
    this.cuota,
    this.suscripcion,
    this.periodoKey,
  });
}

List<Cargo> cargosDeCompras(List<CompraModel> compras) {
  return compras.expand((c) {
    return c.cuotas.map((q) {
      final tipo = q.esComision
          ? TipoCargo.comision
          : (c.numCuotas > 1 ? TipoCargo.cuota : TipoCargo.pagoUnico);
      final etiqueta = q.esComision
          ? 'Comisión inicial'
          : (c.numCuotas > 1 ? 'Cuota ${q.numero} de ${c.numCuotas}' : 'Pago único');
      return Cargo(
        tarjetaId: c.tarjetaId,
        descripcion: c.descripcion,
        etiqueta: etiqueta,
        monto: q.monto,
        moneda: c.moneda,
        fechaVencimiento: q.fechaVencimiento,
        anio: q.anio,
        mes: q.mes,
        pagada: q.pagada,
        fechaPago: q.fechaPago,
        tipo: tipo,
        compra: c,
        cuota: q,
      );
    });
  }).toList();
}

/// Cargos de suscripciones, YA convertidos a la fecha real de pago de su
/// tarjeta (no al día de renovación de la suscripción): Netflix cobra la
/// tarjeta el día 13, pero lo que hay que pagarle al banco por eso cae en
/// el día de pago real de la tarjeta (ej. el 27), igual que cualquier otra
/// compra — así no aparecen fechas "fantasma" que no son de la tarjeta.
List<Cargo> cargosDeSuscripciones(
  List<SuscripcionModel> suscripciones,
  Map<String, TarjetaModel> tarjetasPorId, {
  DateTime? ahora,
}) {
  final hoy = ahora ?? DateTime.now();
  final resultado = <Cargo>[];

  for (final s in suscripciones) {
    final tarjeta = tarjetasPorId[s.tarjetaId];
    if (tarjeta == null) continue;

    final limite = s.activa ? _proximoCobro(hoy, s.diaCobro) : (s.fechaCancelacion ?? hoy);
    var actual = _proximoCobro(s.fechaInicio, s.diaCobro);

    while (!actual.isAfter(limite)) {
      final key = _periodoKey(actual.year, actual.month);
      final vencimiento = proximaFechaPago(fecha: actual, diaCorte: tarjeta.diaCorte, diaPago: tarjeta.diaPago);
      resultado.add(Cargo(
        tarjetaId: s.tarjetaId,
        descripcion: s.descripcion,
        etiqueta: 'Suscripción',
        monto: s.monto,
        moneda: s.moneda,
        fechaVencimiento: vencimiento,
        anio: vencimiento.year,
        mes: vencimiento.month,
        pagada: s.pagos[key] ?? false,
        fechaPago: null,
        tipo: TipoCargo.suscripcion,
        suscripcion: s,
        periodoKey: key,
      ));
      actual = _sumarUnMes(actual, s.diaCobro);
    }
  }

  return resultado;
}

List<Cargo> todosLosCargos(
  List<CompraModel> compras,
  List<SuscripcionModel> suscripciones,
  Map<String, TarjetaModel> tarjetasPorId,
) {
  return [...cargosDeCompras(compras), ...cargosDeSuscripciones(suscripciones, tarjetasPorId)];
}

/// Agrupa cargos de una misma tarjeta que vencen el mismo día (comparten
/// fecha de pago real, ya que el día de cobro/pago es fijo).
class GrupoPago {
  final String tarjetaId;
  final DateTime fecha;
  final List<Cargo> cargos;

  const GrupoPago({required this.tarjetaId, required this.fecha, required this.cargos});

  double totalPorMoneda(Moneda moneda) {
    return cargos.where((c) => c.moneda == moneda).fold(0.0, (s, c) => s + c.monto);
  }

  double totalEnLempiras(double tasaUsdHnl) {
    return totalPorMoneda(Moneda.hnl) + totalPorMoneda(Moneda.usd) * tasaUsdHnl;
  }
}

List<GrupoPago> agruparPorPago(List<Cargo> cargos) {
  final grupos = <String, List<Cargo>>{};
  for (final c in cargos) {
    final f = c.fechaVencimiento;
    final key = '$_prefijoTarjeta${c.tarjetaId}_${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    grupos.putIfAbsent(key, () => []).add(c);
  }
  final lista = grupos.entries.map((e) {
    final primero = e.value.first;
    return GrupoPago(tarjetaId: primero.tarjetaId, fecha: primero.fechaVencimiento, cargos: e.value);
  }).toList();
  lista.sort((a, b) => a.fecha.compareTo(b.fecha));
  return lista;
}

/// Próxima fecha de renovación/cobro de una suscripción (el día que Netflix
/// le cobra a la tarjeta, sin pasar por el ciclo de corte/pago). Para
/// mostrar en una lista aparte de "próximas renovaciones", separada de lo
/// que hay que pagarle al banco por cada tarjeta.
DateTime proximaRenovacionSuscripcion(SuscripcionModel s, {DateTime? ahora}) {
  return _proximoCobro(ahora ?? DateTime.now(), s.diaCobro);
}

const _prefijoTarjeta = 't:';

String _periodoKey(int anio, int mes) => '$anio-${mes.toString().padLeft(2, '0')}';

DateTime _proximoCobro(DateTime referencia, int diaCobro) {
  var anio = referencia.year;
  var mes = referencia.month;
  if (referencia.day > diaCobro) {
    mes += 1;
    if (mes > 12) {
      mes = 1;
      anio += 1;
    }
  }
  return DateTime(anio, mes, _clampDia(anio, mes, diaCobro));
}

DateTime _sumarUnMes(DateTime fecha, int diaCobro) {
  var mes = fecha.month + 1;
  var anio = fecha.year;
  if (mes > 12) {
    mes = 1;
    anio += 1;
  }
  return DateTime(anio, mes, _clampDia(anio, mes, diaCobro));
}

int _clampDia(int anio, int mes, int dia) {
  final diasEnMes = DateTime(anio, mes + 1, 0).day;
  return dia > diasEnMes ? diasEnMes : dia;
}
