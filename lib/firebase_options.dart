import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBeGiaGHCSiWECElkew0PXfdYcvYDK74hw',
      appId: '1:44965394097:android:c0fab6e2ae8ac6a7a05490',
      messagingSenderId: '44965394097',
      projectId: 'futsalgo-d37e0',
      storageBucket: 'futsalgo-d37e0.firebasestorage.app',
    );
  }
}
