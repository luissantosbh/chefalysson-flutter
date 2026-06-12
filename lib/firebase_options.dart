// firebase_options.dart
// Gerado a partir do GoogleService-Info.plist do projeto iOS existente.
//
// ⚠️  Android: para publicar no Android, adicione o app Android no Firebase Console,
//     baixe o google-services.json e substitua os valores em `android` abaixo,
//     ou rode `flutterfire configure` para gerar automaticamente.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web não configurado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma não suportada.');
    }
  }

  // ⚠️  Preencha com os valores do google-services.json ao adicionar Android no Firebase

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWGv8wCPuRZqdodKveeYZX5y_DyPDI2Kg',
    appId: '1:3429544640:android:d5b840388ffc2d727f7325',
    messagingSenderId: '3429544640',
    projectId: 'chefalysson',
    storageBucket: 'chefalysson.firebasestorage.app',
  );
  // Valores extraídos do GoogleService-Info.plist

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8xL1fJxNXqthhkTY8vrg97xSblSrU1PQ',
    appId: '1:3429544640:ios:81198a870203ec997f7325',
    messagingSenderId: '3429544640',
    projectId: 'chefalysson',
    storageBucket: 'chefalysson.firebasestorage.app',
    androidClientId: '3429544640-22b17s4adkt89v5234qkb9g2jcts9eqf.apps.googleusercontent.com',
    iosClientId: '3429544640-ij4kdea7t8bvdd8d4qgt5enupcurind2.apps.googleusercontent.com',
    iosBundleId: 'com.santos.chefAlysson',
  );
}
