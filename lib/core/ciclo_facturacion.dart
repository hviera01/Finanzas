import '../models/cuota_model.dart';

/// Calcula el plan de pagos de una compra según el ciclo de facturación de
/// la tarjeta (día de corte / día de pago), replicando cómo funcionan las
/// "minicuotas" de tarjetas reales (ej. BAC):
///
/// - Si la compra NO se difiere a cuotas (`numCuotas == 1`), es un solo
///   cargo por el monto total, sin comisión, que vence en el próximo pago.
/// - Si se difiere a cuotas (`numCuotas > 1`): la comisión se cobra SOLA en
///   el próximo pago que ya está por vencer (según el corte de la compra), y
///   las cuotas de capital (montoTotal / numCuotas, en partes iguales)
///   arrancan el mes siguiente a ese cobro de comisión, una por mes.
///
/// Regla de ciclo: si la compra cae antes o el mismo día del corte, entra en
/// el corte de ese mes; si cae después, entra en el corte del mes siguiente.
/// El pago de un corte cae el día de pago del mismo mes si ese día es
/// posterior al de corte, o del mes siguiente si no.
List<CuotaModel> calcularCuotas({
  required DateTime fechaCompra,
  required int diaCorte,
  required int diaPago,
  required double montoTotal,
  required int numCuotas,
  required double porcentajeComisionPrimerMes,
}) {
  assert(numCuotas >= 1);

  final primerPago = _proximaFechaPago(fecha: fechaCompra, diaCorte: diaCorte, diaPago: diaPago);

  if (numCuotas == 1) {
    return [
      CuotaModel(
        numero: 1,
        esComision: false,
        monto: _redondear(montoTotal),
        anio: primerPago.year,
        mes: primerPago.month,
        fechaVencimiento: primerPago,
        pagada: false,
        fechaPago: null,
      ),
    ];
  }

  final cuotas = <CuotaModel>[];

  final comision = _redondear(montoTotal * porcentajeComisionPrimerMes / 100);
  cuotas.add(CuotaModel(
    numero: 0,
    esComision: true,
    monto: comision,
    anio: primerPago.year,
    mes: primerPago.month,
    fechaVencimiento: primerPago,
    pagada: false,
    fechaPago: null,
  ));

  final montoBaseCentavos = (montoTotal * 100 / numCuotas).round();
  final totalCentavos = (montoTotal * 100).round();
  int acumuladoCentavos = 0;

  var fechaCuota = _sumarMeses(primerPago, 1, diaPago);
  for (var i = 1; i <= numCuotas; i++) {
    final int montoCentavos;
    if (i < numCuotas) {
      montoCentavos = montoBaseCentavos;
      acumuladoCentavos += montoCentavos;
    } else {
      // La última cuota absorbe el residuo del redondeo.
      montoCentavos = totalCentavos - acumuladoCentavos;
    }

    cuotas.add(CuotaModel(
      numero: i,
      esComision: false,
      monto: montoCentavos / 100,
      anio: fechaCuota.year,
      mes: fechaCuota.month,
      fechaVencimiento: fechaCuota,
      pagada: false,
      fechaPago: null,
    ));

    fechaCuota = _sumarMeses(fechaCuota, 1, diaPago);
  }

  return cuotas;
}

/// La fecha del próximo pago que le corresponde a una compra/cargo hecho en
/// [fecha], dado el corte/pago de la tarjeta.
DateTime _proximaFechaPago({required DateTime fecha, required int diaCorte, required int diaPago}) {
  int corteAnio = fecha.year;
  int corteMes = fecha.month;
  if (fecha.day > diaCorte) {
    corteMes += 1;
    if (corteMes > 12) {
      corteMes = 1;
      corteAnio += 1;
    }
  }

  int pagoAnio = corteAnio;
  int pagoMes = corteMes;
  if (diaPago <= diaCorte) {
    pagoMes += 1;
    if (pagoMes > 12) {
      pagoMes = 1;
      pagoAnio += 1;
    }
  }

  return DateTime(pagoAnio, pagoMes, _clampDia(pagoAnio, pagoMes, diaPago));
}

DateTime _sumarMeses(DateTime fecha, int meses, int diaPago) {
  var mes = fecha.month + meses;
  var anio = fecha.year;
  while (mes > 12) {
    mes -= 12;
    anio += 1;
  }
  return DateTime(anio, mes, _clampDia(anio, mes, diaPago));
}

int _clampDia(int anio, int mes, int dia) {
  final diasEnMes = DateTime(anio, mes + 1, 0).day;
  return dia > diasEnMes ? diasEnMes : dia;
}

double _redondear(double valor) => (valor * 100).round() / 100;
