import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUDAcjhs-f0Zr4t2r9ZcUS4sG-N9Tq8hI',
    appId: '1:92793857271:android:17992c6a01dc12e2c79ff2',
    messagingSenderId: '92793857271',
    projectId: 'chat-app009',
    storageBucket: 'chat-app009.firebasestorage.app',
    databaseURL: 'https://chat-app009-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDk8tuoIlMTbPpogbyG-u68eJGYlVWy6kQ',
    appId: '1:92793857271:ios:fea5fffe43a0dc6cc79ff2',
    messagingSenderId: '92793857271',
    projectId: 'chat-app009',
    storageBucket: 'chat-app009.firebasestorage.app',
    databaseURL: 'https://chat-app009-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDk8tuoIlMTbPpogbyG-u68eJGYlVWy6kQ',
    appId: '1:92793857271:ios:fea5fffe43a0dc6cc79ff2',
    messagingSenderId: '92793857271',
    projectId: 'chat-app009',
    storageBucket: 'chat-app009.firebasestorage.app',
    databaseURL: 'https://chat-app009-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAad2SLsyjoSNfRWVfbi7E0DRH4Fd0_4sc',
    appId: '1:92793857271:web:3ac427635ab2776fc79ff2',
    messagingSenderId: '92793857271',
    projectId: 'chat-app009',
    authDomain: 'chat-app009.firebaseapp.com',
    storageBucket: 'chat-app009.firebasestorage.app',
    databaseURL: 'https://chat-app009-default-rtdb.firebaseio.com',
  );
}
