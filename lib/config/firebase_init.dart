import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:storypilot/firebase_options.dart';

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Firebase init failed — Ask will fall back to stub',
      name: 'FirebaseInit',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
