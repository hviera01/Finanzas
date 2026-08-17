import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suscripcion_model.dart';

class SuscripcionRepository {
  final _col = FirebaseFirestore.instance.collection('suscripciones');

  Stream<List<SuscripcionModel>> observarSuscripciones() {
    return _col.orderBy('descripcion').snapshots().map(
          (s) => s.docs.map((d) => SuscripcionModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> crear(SuscripcionModel suscripcion) {
    return _col.doc(suscripcion.id).set(suscripcion.toMap());
  }

  Future<void> actualizar(SuscripcionModel suscripcion) {
    return _col.doc(suscripcion.id).update(suscripcion.toMap());
  }

  Future<void> eliminar(String id) {
    return _col.doc(id).delete();
  }

  Future<void> cancelar(SuscripcionModel suscripcion) {
    return _col.doc(suscripcion.id).update({
      'activa': false,
      'fechaCancelacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> reactivar(SuscripcionModel suscripcion) {
    return _col.doc(suscripcion.id).update({
      'activa': true,
      'fechaCancelacion': null,
    });
  }

  Future<void> marcarPago(SuscripcionModel suscripcion, String periodoKey, bool pagada) {
    final nuevosPagos = Map<String, bool>.from(suscripcion.pagos);
    if (pagada) {
      nuevosPagos[periodoKey] = true;
    } else {
      nuevosPagos.remove(periodoKey);
    }
    return _col.doc(suscripcion.id).update({'pagos': nuevosPagos});
  }
}
