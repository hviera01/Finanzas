import 'package:cloud_firestore/cloud_firestore.dart';
import 'compra_model.dart';

/// Un cargo recurrente mensual (streaming, software, etc.) que se cobra
/// automáticamente cada mes en el día [diaCobro] de la tarjeta asignada,
/// hasta que el usuario la cancela.
class SuscripcionModel {
  final String id;
  final String tarjetaId;
  final String descripcion;
  final double monto;
  final Moneda moneda;
  final int diaCobro;
  final bool activa;
  final DateTime fechaInicio;
  final DateTime? fechaCancelacion;

  /// Pagos marcados manualmente por período, clave "yyyy-MM". Un período
  /// ausente del mapa se considera pendiente por defecto.
  final Map<String, bool> pagos;

  const SuscripcionModel({
    required this.id,
    required this.tarjetaId,
    required this.descripcion,
    required this.monto,
    required this.moneda,
    required this.diaCobro,
    required this.activa,
    required this.fechaInicio,
    required this.fechaCancelacion,
    required this.pagos,
  });

  SuscripcionModel copyWith({
    String? descripcion,
    double? monto,
    Moneda? moneda,
    int? diaCobro,
    bool? activa,
    DateTime? fechaCancelacion,
  }) {
    return SuscripcionModel(
      id: id,
      tarjetaId: tarjetaId,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      moneda: moneda ?? this.moneda,
      diaCobro: diaCobro ?? this.diaCobro,
      activa: activa ?? this.activa,
      fechaInicio: fechaInicio,
      fechaCancelacion: fechaCancelacion ?? this.fechaCancelacion,
      pagos: pagos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tarjetaId': tarjetaId,
      'descripcion': descripcion,
      'monto': monto,
      'moneda': moneda.codigo,
      'diaCobro': diaCobro,
      'activa': activa,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaCancelacion': fechaCancelacion == null ? null : Timestamp.fromDate(fechaCancelacion!),
      'pagos': pagos,
    };
  }

  factory SuscripcionModel.fromMap(String id, Map<String, dynamic> map) {
    return SuscripcionModel(
      id: id,
      tarjetaId: map['tarjetaId'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      moneda: MonedaX.fromCodigo(map['moneda'] as String? ?? 'HNL'),
      diaCobro: map['diaCobro'] as int? ?? 1,
      activa: map['activa'] as bool? ?? true,
      fechaInicio: (map['fechaInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCancelacion: (map['fechaCancelacion'] as Timestamp?)?.toDate(),
      pagos: Map<String, bool>.from(map['pagos'] as Map? ?? {}),
    );
  }
}
