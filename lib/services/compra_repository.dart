import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/ciclo_facturacion.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';

class CompraRepository {
  final _col = FirebaseFirestore.instance.collection('compras');

  Stream<List<CompraModel>> observarCompras() {
    return _col.orderBy('fecha', descending: true).snapshots().map(
          (s) => s.docs.map((d) => CompraModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<CompraModel>> observarComprasPorTarjeta(String tarjetaId) {
    return _col
        .where('tarjetaId', isEqualTo: tarjetaId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => CompraModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> crear(CompraModel compra) {
    return _col.doc(compra.id).set(compra.toMap());
  }

  Future<void> eliminar(String id) {
    return _col.doc(id).delete();
  }

  Future<void> marcarCuota(CompraModel compra, int numeroCuota, bool pagada) {
    final nuevasCuotas = compra.cuotas.map((c) {
      if (c.numero != numeroCuota) return c;
      return c.copyWith(pagada: pagada, fechaPago: pagada ? DateTime.now() : null);
    }).toList();
    return _col.doc(compra.id).update({
      'cuotas': nuevasCuotas.map((c) => c.toMap()).toList(),
    });
  }

  /// Marca como pagado todo lo que quede pendiente de una compra (comisión
  /// y todas las cuotas), para cuando el usuario decide liquidarla completa
  /// de una sola vez en vez de ir abonando mes a mes.
  Future<void> liquidarTodo(CompraModel compra) {
    final ahora = DateTime.now();
    final nuevasCuotas = compra.cuotas.map((c) {
      if (c.pagada) return c;
      return c.copyWith(pagada: true, fechaPago: ahora);
    }).toList();
    return _col.doc(compra.id).update({
      'cuotas': nuevasCuotas.map((c) => c.toMap()).toList(),
    });
  }

  /// Convierte una compra de pago único a cuotas (estilo "minicuotas"): la
  /// comisión se cobra en el próximo pago a partir de HOY (no de la fecha
  /// original de la compra), y las cuotas de capital arrancan el mes
  /// siguiente. Solo tiene sentido si el pago único todavía no se pagó.
  Future<void> convertirACuotas(
    CompraModel compra, {
    required TarjetaModel tarjeta,
    required int numCuotas,
    required double porcentajeComisionPrimerMes,
  }) {
    final nuevasCuotas = calcularCuotas(
      fechaCompra: DateTime.now(),
      diaCorte: tarjeta.diaCorte,
      diaPago: tarjeta.diaPago,
      montoTotal: compra.montoTotal,
      numCuotas: numCuotas,
      porcentajeComisionPrimerMes: porcentajeComisionPrimerMes,
    );
    return _col.doc(compra.id).update({
      'numCuotas': numCuotas,
      'porcentajeComisionPrimerMes': porcentajeComisionPrimerMes,
      'cuotas': nuevasCuotas.map((c) => c.toMap()).toList(),
    });
  }

  /// Edita los datos base de una compra ya registrada (descripción, monto,
  /// moneda, tarjeta, fecha). Recalcula el plan de pagos con esos datos
  /// nuevos (mismo numCuotas/comisión de antes) y conserva el estado
  /// pagada/fechaPago de cada cuota que siga existiendo (mismo número).
  Future<void> editar(
    CompraModel compra, {
    required TarjetaModel tarjeta,
    required String descripcion,
    required double montoTotal,
    required Moneda moneda,
    required DateTime fecha,
  }) {
    final cuotasRecalculadas = calcularCuotas(
      fechaCompra: fecha,
      diaCorte: tarjeta.diaCorte,
      diaPago: tarjeta.diaPago,
      montoTotal: montoTotal,
      numCuotas: compra.numCuotas,
      porcentajeComisionPrimerMes: compra.porcentajeComisionPrimerMes,
    );
    final pagosPorNumero = {for (final c in compra.cuotas) c.numero: c};
    final nuevasCuotas = cuotasRecalculadas.map((c) {
      final anterior = pagosPorNumero[c.numero];
      if (anterior == null || !anterior.pagada) return c;
      return c.copyWith(pagada: true, fechaPago: anterior.fechaPago);
    }).toList();

    return _col.doc(compra.id).update({
      'tarjetaId': tarjeta.id,
      'descripcion': descripcion,
      'montoTotal': montoTotal,
      'moneda': moneda.codigo,
      'fecha': Timestamp.fromDate(fecha),
      'cuotas': nuevasCuotas.map((c) => c.toMap()).toList(),
    });
  }
}
