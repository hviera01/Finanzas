import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// No es un test de verdad: usa el entorno de flutter_test para renderizar
/// el ícono de la app a PNG (necesitamos `dart:ui` con motor gráfico, que
/// solo está disponible corriendo bajo flutter_test o la app real).
/// Todo se dibuja con formas básicas (sin glifos de fuente de íconos, que
/// no renderizan bien en este entorno de test).
/// Correr con: flutter test test/generar_icono_test.dart
void main() {
  testWidgets('genera assets/icon/icon.png', (tester) async {
    const tamano = 1024.0;
    final key = GlobalKey();

    // El tamaño de superficie de test por defecto es 800x600: hay que
    // agrandarlo para que el Container de 1024x1024 no quede recortado.
    await tester.binding.setSurfaceSize(const Size(tamano, tamano));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            width: tamano,
            height: tamano,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E6E5C), Color(0xFF16A085)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Tarjeta asomando detrás de la billetera.
                Positioned(
                  left: 272,
                  top: 236,
                  child: Container(
                    width: 480,
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0A324),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 34, 36, 0),
                      child: Container(height: 26, width: 130, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ),
                // Cuerpo de la billetera.
                Positioned(
                  left: 202,
                  top: 452,
                  child: Container(
                    width: 620,
                    height: 372,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(56),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 10))],
                    ),
                  ),
                ),
                // Broche.
                Positioned(
                  left: 712 - 54,
                  top: 452 - 54,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(color: Color(0xFF10201C), shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(color: Color(0xFFE0A324), shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory('assets/icon');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('assets/icon/icon.png').writeAsBytesSync(bytes);
  });
}
