import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_hermana/core/ciclo_facturacion.dart';

void main() {
  group('calcularCuotas', () {
    test('pago único (numCuotas=1) no lleva comisión', () {
      final cuotas = calcularCuotas(
        fechaCompra: DateTime(2026, 8, 10),
        diaCorte: 15,
        diaPago: 27,
        montoTotal: 500,
        numCuotas: 1,
        porcentajeComisionPrimerMes: 0,
      );
      expect(cuotas.length, 1);
      expect(cuotas[0].esComision, false);
      expect(cuotas[0].monto, 500);
      // Compra antes del corte (15) -> paga en el corte de este mes, día 27.
      expect(cuotas[0].fechaVencimiento, DateTime(2026, 8, 27));
    });

    test('compra después del corte cae en el corte del mes siguiente', () {
      final cuotas = calcularCuotas(
        fechaCompra: DateTime(2026, 8, 20),
        diaCorte: 15,
        diaPago: 27,
        montoTotal: 100,
        numCuotas: 1,
        porcentajeComisionPrimerMes: 0,
      );
      expect(cuotas[0].fechaVencimiento, DateTime(2026, 9, 27));
    });

    test('caso real BAC: 12,949 a 3 cuotas con 6% de comisión', () {
      final cuotas = calcularCuotas(
        fechaCompra: DateTime(2026, 8, 10),
        diaCorte: 15,
        diaPago: 27,
        montoTotal: 12949,
        numCuotas: 3,
        porcentajeComisionPrimerMes: 6,
      );
      // comisión sola + 3 cuotas = 4 cargos
      expect(cuotas.length, 4);

      final comision = cuotas.first;
      expect(comision.esComision, true);
      expect(comision.monto, closeTo(776.94, 0.01));
      expect(comision.fechaVencimiento, DateTime(2026, 8, 27));

      final cuota1 = cuotas[1];
      final cuota2 = cuotas[2];
      final cuota3 = cuotas[3];
      expect(cuota1.numero, 1);
      expect(cuota1.monto, closeTo(4316.33, 0.01));
      expect(cuota1.fechaVencimiento, DateTime(2026, 9, 27));
      expect(cuota2.fechaVencimiento, DateTime(2026, 10, 27));
      expect(cuota3.fechaVencimiento, DateTime(2026, 11, 27));

      // La suma de las 3 cuotas de capital debe cuadrar exacto con el total.
      final sumaCuotas = cuota1.monto + cuota2.monto + cuota3.monto;
      expect(sumaCuotas, closeTo(12949.0, 0.001));
    });

    test('día de pago menor o igual al de corte pasa al mes siguiente', () {
      final cuotas = calcularCuotas(
        fechaCompra: DateTime(2026, 8, 5),
        diaCorte: 20,
        diaPago: 5,
        montoTotal: 100,
        numCuotas: 1,
        porcentajeComisionPrimerMes: 0,
      );
      // Corte de agosto (día 20), pago (día 5) <= corte -> mes siguiente.
      expect(cuotas[0].fechaVencimiento, DateTime(2026, 9, 5));
    });

    test('día de pago se ajusta (clamp) en meses cortos como febrero', () {
      final cuotas = calcularCuotas(
        fechaCompra: DateTime(2026, 1, 10),
        diaCorte: 15,
        diaPago: 31,
        montoTotal: 300,
        numCuotas: 2,
        porcentajeComisionPrimerMes: 5,
      );
      // Comisión: corte de enero, pago día 31 -> 31 ene.
      expect(cuotas[0].fechaVencimiento, DateTime(2026, 1, 31));
      // Cuota 1 un mes después: 28 feb (2026 no es bisiesto).
      expect(cuotas[1].fechaVencimiento, DateTime(2026, 2, 28));
      // Cuota 2: 31 mar.
      expect(cuotas[2].fechaVencimiento, DateTime(2026, 3, 31));
    });
  });
}
