import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService(this._prefs, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  static const pendingEmailKey = 'pending_sign_in_email';

  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get pendingEmail => _prefs.getString(pendingEmailKey);

  bool isSignInWithEmailLink(String link) =>
      _auth.isSignInWithEmailLink(link);

  Future<void> sendSignInLink(String email) async {
    final continueUrl = '${Uri.base.origin}/login';
    final actionCodeSettings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
    );
    await _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: actionCodeSettings,
    );
    await _prefs.setString(pendingEmailKey, email.trim());
  }

  Future<void> completeSignInWithEmailLink(String email, String link) async {
    await _auth.signInWithEmailLink(email: email, emailLink: link);
    await _prefs.remove(pendingEmailKey);
  }

  Future<void> signOut() => _auth.signOut();
}
