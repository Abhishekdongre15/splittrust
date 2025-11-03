// ignore_for_file: public_member_api_docs

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        throw UnsupportedError('FirebaseOptions have not been configured for macOS.');
      case TargetPlatform.windows:
        throw UnsupportedError('FirebaseOptions have not been configured for Windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('FirebaseOptions have not been configured for Linux.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzRSwE3QXUeiHPUiopcXouQEzqJ5U1kMo',
    appId: '1:592959853320:web:00b0a6abb7431a8c0952bd',
    messagingSenderId: '592959853320',
    projectId: 'splittrust-3bccc',
    authDomain: 'splittrust-3bccc.firebaseapp.com',
    storageBucket: 'splittrust-3bccc.firebasestorage.app',
    measurementId: 'G-Q3VNJP4LQH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIjSouteY__mRfJx93LjU0Q9FdUtBu27o',
    appId: '1:592959853320:android:9ecf6ee4676c3d460952bd',
    messagingSenderId: '592959853320',
    projectId: 'splittrust-3bccc',
    storageBucket: 'splittrust-3bccc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzRSwE3QXUeiHPUiopcXouQEzqJ5U1kMo',
    appId: '1:592959853320:ios:placeholder000000',
    messagingSenderId: '592959853320',
    projectId: 'splittrust-3bccc',
    storageBucket: 'splittrust-3bccc.firebasestorage.app',
    iosBundleId: 'com.aquafiresolutions.splittrust',
  );
}
