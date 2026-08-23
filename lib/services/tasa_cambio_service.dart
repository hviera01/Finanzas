import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TasaCambio {
  final double valor;
  final DateTime fecha;
  final bool esCache;

  const TasaCambio({required this.valor, required this.fecha, required this.esCache});
}

class TasaCambioService {
  static const _urlApi = 'https://open.er-api.com/v6/latest/USD';
  static const _keyValor = 'tasa_hnl_valor';
  static const _keyFecha = 'tasa_hnl_fecha';

  // El tipo de cambio interbancario (el que devuelve la API) siempre queda
  // un poco por debajo de lo que realmente cobra un banco/tarjeta al
  // convertir un cargo en dólares (spread + comisión de la red). Se le
  // agrega un margen de seguridad para que la app nunca se quede corta:
  // mejor que sobre un poco a que falte.
  static const _margenSeguridad = 1.03;

  // Si el último fetch exitoso quedó cacheado hace más de esto, ya no se
  // confía ciegamente en ese número (podría ser de hace meses) — se usa
  // el respaldo fijo en su lugar, que se actualiza a mano de vez en cuando.
  static const _antiguedadMaximaCache = Duration(days: 7);

  // Respaldo fijo para cuando no hay fetch reciente ni caché confiable.
  // Puesto deliberadamente por encima del tipo de cambio real de HNL para
  // no subestimar — actualizar de vez en cuando si el Lempira se mueve mucho.
  static const _respaldoFijo = 28.0;

  Future<TasaCambio> obtenerTasaUsdHnl() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await http.get(Uri.parse(_urlApi)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        final hnl = (rates?['HNL'] as num?)?.toDouble();
        if (hnl != null && hnl > 0) {
          final ahora = DateTime.now();
          await prefs.setDouble(_keyValor, hnl);
          await prefs.setString(_keyFecha, ahora.toIso8601String());
          return TasaCambio(valor: hnl * _margenSeguridad, fecha: ahora, esCache: false);
        }
      }
    } catch (_) {
      // sin conexión / API caída: cae al valor cacheado abajo
    }

    final cacheValor = prefs.getDouble(_keyValor);
    final cacheFechaStr = prefs.getString(_keyFecha);
    if (cacheValor != null && cacheFechaStr != null) {
      final cacheFecha = DateTime.parse(cacheFechaStr);
      final antiguedad = DateTime.now().difference(cacheFecha);
      if (antiguedad <= _antiguedadMaximaCache) {
        return TasaCambio(valor: cacheValor * _margenSeguridad, fecha: cacheFecha, esCache: true);
      }
    }

    // Sin fetch reciente ni caché confiable: respaldo fijo (ya incluye margen).
    return TasaCambio(valor: _respaldoFijo, fecha: DateTime.now(), esCache: true);
  }
}
