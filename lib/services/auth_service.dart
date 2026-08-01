import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Admin authentication: Firebase email/password when cloud is on,
/// otherwise shared local password.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth? _auth;
  bool cloudEnabled = false;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  bool get isFirebaseAdminSignedIn =>
      cloudEnabled && auth.currentUser != null;

  /// Returns null on success, error message on failure.
  Future<String?> signInAdmin({
    required String password,
    String? email,
  }) async {
    if (!cloudEnabled) {
      if (password.trim() != kLocalAdminPassword) {
        return 'Wrong admin password';
      }
      return null;
    }

    final mail = (email ?? '').trim();
    if (mail.isEmpty) {
      // Allow local password without email (emergency / Auth not ready).
      if (password.trim() == kLocalAdminPassword) return null;
      return 'Enter admin email';
    }

    try {
      await auth.signInWithEmailAndPassword(
        email: mail,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      // Allow local password as emergency fallback for Sunday ops.
      if (password.trim() == kLocalAdminPassword) {
        debugPrint('Firebase Auth failed (${e.code}); using local admin gate');
        return null;
      }
      return e.message ?? e.code;
    } catch (e) {
      if (password.trim() == kLocalAdminPassword) return null;
      return '$e';
    }
  }

  Future<void> signOut() async {
    if (!cloudEnabled) return;
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Firebase signOut: $e');
    }
  }
}
