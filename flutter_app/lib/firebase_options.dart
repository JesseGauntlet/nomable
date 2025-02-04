import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// TODO: Replace with actual Firebase configuration
// You'll need to:
// 1. Create a Firebase project in the Firebase Console
// 2. Register your app (iOS/Android)
// 3. Download the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
// 4. Replace these placeholder values with your actual Firebase configuration

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not supported yet.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRWbX2Hxep0lw4F3oLeGrERMTlaTzmtgs',
    appId: '1:181799688241:android:2dd76dba3b6f6bc0e2dd10',
    messagingSenderId: '181799688241',
    projectId: 'foodtalk-f468d',
    storageBucket: 'foodtalk-f468d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBpVDlrS-G8D4bGwoAjlfAPLmsIfO2kFRs',
    appId: '1:181799688241:ios:fa676f5a89ccbad8e2dd10',
    messagingSenderId: '181799688241',
    projectId: 'foodtalk-f468d',
    storageBucket: 'foodtalk-f468d.firebasestorage.app',
    iosClientId: '181799688241-tr98gaedftuvdhm4f2otkvuqm4j6ef6t.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApp',
  );

}