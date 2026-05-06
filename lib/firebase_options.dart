// TODO: Replace this file with the actual firebase_options.dart generated
// by running `flutterfire configure` in your project root.
// This is a placeholder to allow compilation without Firebase configuration.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Run `flutterfire configure` to generate real options.
class DefaultFirebaseOptions {
  /// Returns the [FirebaseOptions] for the current platform.
  static FirebaseOptions get currentPlatform {
    // TODO: Replace these placeholder values with your actual Firebase config
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure to generate.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace all placeholder values below with your Firebase project config.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDL2eD9MqMgFFI4nUU_HglUsFh-no3KMk4',
    appId: '1:157498430315:web:c88e527039919dae3bf22e',
    messagingSenderId: '157498430315',
    projectId: 'queuemate-2b55d',
    authDomain: 'queuemate-2b55d.firebaseapp.com',
    storageBucket: 'queuemate-2b55d.firebasestorage.app',
    measurementId: 'G-JV5CN9Z971',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCo5byyJ-cEzLCeLXvIsUWXKqOIfBuIjkc',
    appId: '1:157498430315:android:c7f910196a4951543bf22e',
    messagingSenderId: '157498430315',
    projectId: 'queuemate-2b55d',
    storageBucket: 'queuemate-2b55d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIorDOymq-vIHWrTIpyIPZJ_VqmOIk5u0',
    appId: '1:157498430315:ios:0b840dc56745000b3bf22e',
    messagingSenderId: '157498430315',
    projectId: 'queuemate-2b55d',
    storageBucket: 'queuemate-2b55d.firebasestorage.app',
    iosBundleId: 'com.example.queuemate',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBIorDOymq-vIHWrTIpyIPZJ_VqmOIk5u0',
    appId: '1:157498430315:ios:0b840dc56745000b3bf22e',
    messagingSenderId: '157498430315',
    projectId: 'queuemate-2b55d',
    storageBucket: 'queuemate-2b55d.firebasestorage.app',
    iosBundleId: 'com.example.queuemate',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDL2eD9MqMgFFI4nUU_HglUsFh-no3KMk4',
    appId: '1:157498430315:web:34bd2191aa16fa113bf22e',
    messagingSenderId: '157498430315',
    projectId: 'queuemate-2b55d',
    authDomain: 'queuemate-2b55d.firebaseapp.com',
    storageBucket: 'queuemate-2b55d.firebasestorage.app',
    measurementId: 'G-C1P2L1X4MS',
  );

}