// File generated for Firebase project fpl-fees.
// Regenerated manually after FlutterFire Xcode bundling failed (xcodeproj gem).
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  /// Real project — not REPLACE_* placeholders.
  static bool get configured => currentPlatform.projectId == 'fpl-fees';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnb3W_r15O2HrirfZwx9mQC3fq9m8Ih9o',
    appId: '1:283215487299:web:b47bff1084c2a75a8b4ff6',
    messagingSenderId: '283215487299',
    projectId: 'fpl-fees',
    authDomain: 'fpl-fees.firebaseapp.com',
    storageBucket: 'fpl-fees.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBf8NbCBgtPpMNgEZJYruxFQIz4e3Ts1oo',
    appId: '1:283215487299:android:c17cf44bf9cd9e2c8b4ff6',
    messagingSenderId: '283215487299',
    projectId: 'fpl-fees',
    storageBucket: 'fpl-fees.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWdPWv54x62IVd_eMpN0GLPFLa7leCF0I',
    appId: '1:283215487299:ios:c6c8722ad48fb7df8b4ff6',
    messagingSenderId: '283215487299',
    projectId: 'fpl-fees',
    storageBucket: 'fpl-fees.firebasestorage.app',
    iosBundleId: 'com.fpl.fplFees',
  );
}
