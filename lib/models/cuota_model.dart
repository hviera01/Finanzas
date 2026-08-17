import 'package:cloud_firestore/cloud_firestore.dart';

/// Un cargo dentro del plan de pagos de una compra.
/// `numero == 0` representa el cargo de comisión inicial (solo existe si la
/// compra se difirió a cuotas); `numero >= 1` son las cuotas de capital,
/// 1 de [totalCuotas] a [totalCuotas] de [totalCuotas].
class CuotaModel {
  final int numero;
  final bool esComision;
  final double monto;
  final int anio;
  final int mes;
  final DateTime fechaVencimiento;
  final bool pagada;
  final DateTime? fechaPago;

  const CuotaModel({
    required this.numero,
    required this.esComision,
    required this.monto,
    required this.anio,
    required this.mes,
    required this.fechaVencimiento,
    required this.pagada,
    required this.fechaPago,
  });

  CuotaModel copyWith({
    bool? pagada,
    DateTime? fechaPago,
  }) {
    return CuotaModel(
      numero: numero,
      esComision: esComision,
      monto: monto,
      anio: anio,
      mes: mes,
      fechaVencimiento: fechaVencimiento,
      pagada: pagada ?? this.pagada,
      fechaPago: fechaPago ?? this.fechaPago,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'esComision': esComision,
      'monto': monto,
      'anio': anio,
      'mes': mes,
      'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
      'pagada': pagada,
      'fechaPago': fechaPago == null ? null : Timestamp.fromDate(fechaPago!),
    };
  }

  factory CuotaModel.fromMap(Map<String, dynamic> map) {
    return CuotaModel(
      numero: map['numero'] as int,
      esComision: map['esComision'] as bool? ?? false,
      monto: (map['monto'] as num).toDouble(),
      anio: map['anio'] as int,
      mes: map['mes'] as int,
      fechaVencimiento: (map['fechaVencimiento'] as Timestamp).toDate(),
      pagada: map['pagada'] as bool? ?? false,
      fechaPago: map['fechaPago'] == null ? null : (map['fechaPago'] as Timestamp).toDate(),
    );
  }
}
