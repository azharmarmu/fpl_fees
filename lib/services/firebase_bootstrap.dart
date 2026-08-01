import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../firebase_options.dart';

/// Result of attempting Firebase initialization at app start.
class FirebaseBootstrap {
  FirebaseBootstrap._({required this.enabled, this.error});

  final bool enabled;
  final String? error;

  bool get failed => error != null;

  static Future<FirebaseBootstrap> init() async {
    if (!kFirebaseEnabled) {
      return FirebaseBootstrap._(enabled: false);
    }
    if (!DefaultFirebaseOptions.configured) {
      debugPrint(
        'Firebase flag on but options still REPLACE_* — staying local. '
        'Run: flutterfire configure',
      );
      return FirebaseBootstrap._(
        enabled: false,
        error: 'Firebase options not configured. Run flutterfire configure.',
      );
    }
    if (kIsWeb && !kAllowFirebaseOnWeb) {
      return FirebaseBootstrap._(enabled: false);
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return FirebaseBootstrap._(enabled: true);
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      return FirebaseBootstrap._(
        enabled: false,
        error: 'Firebase init failed: $e',
      );
    }
  }
}
