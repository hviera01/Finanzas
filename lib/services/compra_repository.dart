import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compra_model.dart';

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
}
