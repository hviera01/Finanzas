import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_hermana/core/cargos.dart';
import 'package:tarjetas_hermana/models/compra_model.dart';
import 'package:tarjetas_hermana/models/suscripcion_model.dart';

SuscripcionModel _suscripcion({
  required DateTime fechaInicio,
  required int diaCobro,
  bool activa = true,
  DateTime? fechaCancelacion,
  Map<String, bool> pagos = const {},
}) {
  return SuscripcionModel(
    id: 's1',
    tarjetaId: 't1',
    descripcion: 'Netflix',
    monto: 379,
    moneda: Moneda.hnl,
    diaCobro: diaCobro,
    activa: activa,
    fechaInicio: fechaInicio,
    fechaCancelacion: fechaCancelacion,
    pagos: pagos,
  );
}

void main() {
  group('cargosDeSuscripciones', () {
    test('genera un cargo por mes activo, incluyendo el próximo por vencer', () {
      final s = _suscripcion(fechaInicio: DateTime(2026, 6, 10), diaCobro: 15);
      final cargos = cargosDeSuscripciones([s], ahora: DateTime(2026, 8, 17));

      expect(cargos.length, 4);
      expect(cargos.map((c) => c.fechaVencimiento), [
        DateTime(2026, 6, 15),
        DateTime(2026, 7, 15),
        DateTime(2026, 8, 15),
        DateTime(2026, 9, 15),
      ]);
      expect(cargos.every((c) => c.tipo == TipoCargo.suscripcion), true);
      expect(cargos.every((c) => !c.pagada), true);
    });

    test('una suscripción cancelada no genera cargos despues de la cancelación', () {
      final s = _suscripcion(
        fechaInicio: DateTime(2026, 6, 10),
        diaCobro: 15,
        activa: false,
        fechaCancelacion: DateTime(2026, 7, 20),
      );
      final cargos = cargosDeSuscripciones([s], ahora: DateTime(2026, 9, 1));

      expect(cargos.map((c) => c.fechaVencimiento), [
        DateTime(2026, 6, 15),
        DateTime(2026, 7, 15),
      ]);
    });

    test('los pagos marcados en el mapa se reflejan como pagada', () {
      final s = _suscripcion(
        fechaInicio: DateTime(2026, 6, 10),
        diaCobro: 15,
        pagos: {'2026-06': true},
      );
      final cargos = cargosDeSuscripciones([s], ahora: DateTime(2026, 6, 12));

      expect(cargos.length, 1);
      expect(cargos.first.pagada, true);
      expect(cargos.first.periodoKey, '2026-06');
    });
  });
}
