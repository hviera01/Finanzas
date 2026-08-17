import 'package:cloud_firestore/cloud_firestore.dart';

class TarjetaModel {
  final String id;
  final String nombre;
  final int diaCorte;
  final int diaPago;
  final bool activa;
  final DateTime createdAt;

  const TarjetaModel({
    required this.id,
    required this.nombre,
    required this.diaCorte,
    required this.diaPago,
    required this.activa,
    required this.createdAt,
  });

  TarjetaModel copyWith({
    String? nombre,
    int? diaCorte,
    int? diaPago,
    bool? activa,
  }) {
    return TarjetaModel(
      id: id,
      nombre: nombre ?? this.nombre,
      diaCorte: diaCorte ?? this.diaCorte,
      diaPago: diaPago ?? this.diaPago,
      activa: activa ?? this.activa,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'diaCorte': diaCorte,
      'diaPago': diaPago,
      'activa': activa,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TarjetaModel.fromMap(String id, Map<String, dynamic> map) {
    return TarjetaModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      diaCorte: map['diaCorte'] as int? ?? 1,
      diaPago: map['diaPago'] as int? ?? 1,
      activa: map['activa'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
