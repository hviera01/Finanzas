import 'package:cloud_firestore/cloud_firestore.dart';
import 'cuota_model.dart';

enum Moneda { usd, hnl }

extension MonedaX on Moneda {
  String get codigo => this == Moneda.usd ? 'USD' : 'HNL';
  String get simbolo => this == Moneda.usd ? '\$' : 'L';

  static Moneda fromCodigo(String codigo) {
    return codigo == 'USD' ? Moneda.usd : Moneda.hnl;
  }
}

class CompraModel {
  final String id;
  final String tarjetaId;
  final String descripcion;
  final double montoTotal;
  final Moneda moneda;
  final DateTime fecha;
  final int numCuotas;
  final double porcentajeComisionPrimerMes;
  final DateTime createdAt;
  final List<CuotaModel> cuotas;

  const CompraModel({
    required this.id,
    required this.tarjetaId,
    required this.descripcion,
    required this.montoTotal,
    required this.moneda,
    required this.fecha,
    required this.numCuotas,
    required this.porcentajeComisionPrimerMes,
    required this.createdAt,
    required this.cuotas,
  });

  double get totalPagado => cuotas.where((c) => c.pagada).fold(0.0, (s, c) => s + c.monto);
  double get totalPendiente => cuotas.where((c) => !c.pagada).fold(0.0, (s, c) => s + c.monto);
  bool get liquidada => cuotas.every((c) => c.pagada);
  int get cuotasPagadas => cuotas.where((c) => c.pagada).length;

  CompraModel copyWith({List<CuotaModel>? cuotas}) {
    return CompraModel(
      id: id,
      tarjetaId: tarjetaId,
      descripcion: descripcion,
      montoTotal: montoTotal,
      moneda: moneda,
      fecha: fecha,
      numCuotas: numCuotas,
      porcentajeComisionPrimerMes: porcentajeComisionPrimerMes,
      createdAt: createdAt,
      cuotas: cuotas ?? this.cuotas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tarjetaId': tarjetaId,
      'descripcion': descripcion,
      'montoTotal': montoTotal,
      'moneda': moneda.codigo,
      'fecha': Timestamp.fromDate(fecha),
      'numCuotas': numCuotas,
      'porcentajeComisionPrimerMes': porcentajeComisionPrimerMes,
      'createdAt': Timestamp.fromDate(createdAt),
      'cuotas': cuotas.map((c) => c.toMap()).toList(),
    };
  }

  factory CompraModel.fromMap(String id, Map<String, dynamic> map) {
    return CompraModel(
      id: id,
      tarjetaId: map['tarjetaId'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      montoTotal: (map['montoTotal'] as num?)?.toDouble() ?? 0,
      moneda: MonedaX.fromCodigo(map['moneda'] as String? ?? 'HNL'),
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numCuotas: map['numCuotas'] as int? ?? 1,
      porcentajeComisionPrimerMes: (map['porcentajeComisionPrimerMes'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cuotas: ((map['cuotas'] as List?) ?? [])
          .map((c) => CuotaModel.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }
}
