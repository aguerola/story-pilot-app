import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:storypilot/config/env.dart';
import 'package:storypilot/firebase_options.dart';

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (Env.useFunctionsEmulator) {
      FirebaseFunctions.instanceFor(region: Env.functionsRegion)
          .useFunctionsEmulator('localhost', 5001);
    }
  } catch (error, stackTrace) {
    developer.log(
      'Firebase init failed — Cloud Functions unavailable',
      name: 'FirebaseInit',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
