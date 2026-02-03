import 'package:firebase_core/firebase_core.dart';

/// Service for Firebase initialization and configuration
class FirebaseService {
  static FirebaseService? _instance;

  FirebaseService._();

  /// Get singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
}