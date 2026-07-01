import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (!kIsWeb) return null;
    return const FirebaseOptions(
      apiKey: 'AIzaSyBu5HDs_wuhKy7A5sCjdvNZY4t5vnZ6Fag',
      appId: '1:962109579563:web:a0fa92699be3cf861ee56e',
      messagingSenderId: '962109579563',
      projectId: 'coop-commerce-8d43f',
      authDomain: 'coop-commerce-8d43f.firebaseapp.com',
      databaseURL: 'https://coop-commerce-8d43f-default-rtdb.firebaseio.com',
      storageBucket: 'coop-commerce-8d43f.firebasestorage.app',
      measurementId: 'G-9TZPP2SJ05',
    );
  }
}
