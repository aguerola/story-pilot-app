import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFueW7ol-EUTmpCuxyzFYQQfgN3J1zpfU',
    appId: '1:495865262735:web:c446d0eeaca5f1fcd3b6fa',
    messagingSenderId: '495865262735',
    projectId: 'storypilot-35945',
    authDomain: 'storypilot-35945.firebaseapp.com',
    storageBucket: 'storypilot-35945.firebasestorage.app',
    measurementId: 'G-MQ3ZJXC62Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'unset'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'unset'),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'unset',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'unset',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'unset'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'unset'),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'unset',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'unset',
    ),
    iosBundleId: 'app.storypilot',
  );
}