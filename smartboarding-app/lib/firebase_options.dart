// ⚠️  ATENÇÃO: Este arquivo é um template.
//
// Gere a versão real executando:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// O arquivo gerado conterá os valores reais do seu projeto Firebase.
// Não faça commit dos valores reais — adicione firebase_options.dart
// ao .gitignore ou use variáveis de ambiente em produção.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plataforma não suportada pelo Firebase: $defaultTargetPlatform',
        );
    }
  }

  // TODO: substitua pelos valores gerados pelo `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
    iosClientId: 'TODO',
    iosBundleId: 'TODO',
  );

  // Nota: Firebase Messaging na web requer um service worker.
  // Crie web/firebase-messaging-sw.js após rodar `flutter create . --platforms web`
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
    authDomain: 'TODO',
  );
}
