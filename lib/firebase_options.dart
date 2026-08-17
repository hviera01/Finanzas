// Generado por `flutterfire configure` para el proyecto Firebase "Finanzas"
// (finanzas-c2674). Solo se configuró la plataforma web.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions no está configurado para $defaultTargetPlatform. '
      'Corré `flutterfire configure` en este proyecto.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXqrLUVs1Tg6FGknnhcziMqAtu6YF3x4o',
    appId: '1:761653821494:web:063ce1adb53578de079897',
    messagingSenderId: '761653821494',
    projectId: 'finanzas-c2674',
    authDomain: 'finanzas-c2674.firebaseapp.com',
    storageBucket: 'finanzas-c2674.firebasestorage.app',
  );
}
