import 'package:firebase_core/firebase_core.dart';
import 'package:storypilot/firebase_options.dart';

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase not configured — Ask falls back to stub.
  }
}
