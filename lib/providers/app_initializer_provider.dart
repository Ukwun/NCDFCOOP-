import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/providers/cart_provider.dart';

/// App Initialization Provider
/// This initializes critical app systems on startup
class AppInitializerNotifier extends Notifier<bool> {
  @override
  bool build() {
    _initializeApp();
    return true;
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initializing app systems...');

      // Wait for Firebase auth to be ready
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null) {
        debugPrint('👤 User logged in: ${user.email}');

        // Initialize cart from Firestore for logged-in user
        debugPrint('📦 Loading cart from Firestore...');
        try {
          await ref.read(cartProvider.notifier).initializeCart();
          debugPrint('✅ Cart initialized successfully');
        } catch (e) {
          debugPrint('⚠️  Cart initialization warning: $e');
          // Non-blocking error - app continues without cart
        }
      } else {
        debugPrint('😐 No user logged in, starting with empty cart');
      }

      debugPrint('✅ App initialization complete');
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      // Non-blocking - app continues anyway
    }
  }
}

/// Provider for app initialization
final appInitializerProvider = NotifierProvider<AppInitializerNotifier, bool>(
  () => AppInitializerNotifier(),
);
