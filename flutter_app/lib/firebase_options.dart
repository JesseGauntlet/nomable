import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the app
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
      default:
        throw UnsupportedError(
          'Unsupported platform: ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpVDlrS-G8D4bGwoAjlfAPLmsIfO2kFRs',
    authDomain: 'foodtalk-f468d.firebaseapp.com',
    projectId: 'foodtalk-f468d',
    storageBucket: 'foodtalk-f468d.appspot.com',
    messagingSenderId: '181799688241',
    appId: '1:181799688241:web:fa676f5a89ccbad8e2dd10',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRWbX2Hxep0lw4F3oLeGrERMTlaTzmtgs',
    appId: '1:181799688241:android:2dd76dba3b6f6bc0e2dd10',
    messagingSenderId: '181799688241',
    projectId: 'foodtalk-f468d',
    storageBucket: 'foodtalk-f468d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBpVDlrS-G8D4bGwoAjlfAPLmsIfO2kFRs',
    appId: '1:181799688241:ios:fa676f5a89ccbad8e2dd10',
    messagingSenderId: '181799688241',
    projectId: 'foodtalk-f468d',
    storageBucket: 'foodtalk-f468d.appspot.com',
    iosClientId:
        '181799688241-tr98gaedftuvdhm4f2otkvuqm4j6ef6t.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApp',
  );
}
