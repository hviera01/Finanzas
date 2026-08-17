import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  final _doc = FirebaseFirestore.instance.collection('config').doc('general');
  static const _keyDispositivoConfiable = 'dispositivo_confiable_hash';

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _generarSalt() {
    final rnd = Random.secure();
    return List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<bool> existePin() async {
    final snap = await _doc.get();
    return snap.exists && (snap.data()?['pinHash'] as String?)?.isNotEmpty == true;
  }

  Future<void> crearPin(String pin) async {
    final salt = _generarSalt();
    final hash = _hashPin(pin, salt);
    await _doc.set({'pinHash': hash, 'pinSalt': salt});
  }

  Future<bool> verificarPin(String pin) async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null) return false;
    final salt = data['pinSalt'] as String?;
    final hash = data['pinHash'] as String?;
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  Future<void> recordarDispositivo(String pin) async {
    final snap = await _doc.get();
    final hash = snap.data()?['pinHash'] as String?;
    if (hash == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDispositivoConfiable, hash);
  }

  Future<bool> dispositivoEsConfiable() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_keyDispositivoConfiable);
    if (guardado == null) return false;
    final snap = await _doc.get();
    final hashActual = snap.data()?['pinHash'] as String?;
    return guardado.isNotEmpty && guardado == hashActual;
  }

  Future<void> olvidarDispositivo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDispositivoConfiable);
  }
}
