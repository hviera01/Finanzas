import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta_model.dart';

class TarjetaRepository {
  final _col = FirebaseFirestore.instance.collection('tarjetas');

  Stream<List<TarjetaModel>> observarTarjetas() {
    return _col.orderBy('nombre').snapshots().map(
          (s) => s.docs.map((d) => TarjetaModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> crear(TarjetaModel tarjeta) {
    return _col.doc(tarjeta.id).set(tarjeta.toMap());
  }

  Future<void> actualizar(TarjetaModel tarjeta) {
    return _col.doc(tarjeta.id).update(tarjeta.toMap());
  }

  Future<void> eliminar(String id) {
    return _col.doc(id).delete();
  }
}
