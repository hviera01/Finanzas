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
          return TasaCambio(valor: hnl, fecha: ahora, esCache: false);
        }
      }
    } catch (_) {
      // sin conexión / API caída: cae al valor cacheado abajo
    }

    final cacheValor = prefs.getDouble(_keyValor);
    final cacheFechaStr = prefs.getString(_keyFecha);
    if (cacheValor != null && cacheFechaStr != null) {
      return TasaCambio(valor: cacheValor, fecha: DateTime.parse(cacheFechaStr), esCache: true);
    }

    // Último respaldo si nunca hubo conexión ni caché: tasa aproximada fija.
    return TasaCambio(valor: 25.4, fecha: DateTime.now(), esCache: true);
  }
}
