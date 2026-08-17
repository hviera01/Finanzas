import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/compra_model.dart';
import '../models/suscripcion_model.dart';
import '../models/tarjeta_model.dart';
import '../services/compra_repository.dart';
import '../services/pin_service.dart';
import '../services/suscripcion_repository.dart';
import '../services/tarjeta_repository.dart';
import '../services/tasa_cambio_service.dart';

final tarjetaRepositoryProvider = Provider((ref) => TarjetaRepository());
final compraRepositoryProvider = Provider((ref) => CompraRepository());
final suscripcionRepositoryProvider = Provider((ref) => SuscripcionRepository());
final pinServiceProvider = Provider((ref) => PinService());
final tasaCambioServiceProvider = Provider((ref) => TasaCambioService());

final tarjetasProvider = StreamProvider<List<TarjetaModel>>((ref) {
  return ref.watch(tarjetaRepositoryProvider).observarTarjetas();
});

final comprasProvider = StreamProvider<List<CompraModel>>((ref) {
  return ref.watch(compraRepositoryProvider).observarCompras();
});

final suscripcionesProvider = StreamProvider<List<SuscripcionModel>>((ref) {
  return ref.watch(suscripcionRepositoryProvider).observarSuscripciones();
});

final tasaCambioProvider = FutureProvider<TasaCambio>((ref) {
  return ref.watch(tasaCambioServiceProvider).obtenerTasaUsdHnl();
});

/// Estado de desbloqueo de la app (PIN). Vive solo en memoria: se resetea
/// al recargar la pestaña salvo que el dispositivo esté marcado confiable.
final desbloqueadoProvider = StateProvider<bool>((ref) => false);
