import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'env_config.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static bool _emulatorsConnected = false;

  static Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: _getFirebaseOptions(),
    );

    // Connect to emulators in local environment
    // IMPORTANT: Must connect to emulators BEFORE any Firebase operations
    if (EnvConfig.isLocal && !_emulatorsConnected) {
      await _connectToEmulators();
      _emulatorsConnected = true;
    }

    if (kDebugMode) {
      print('🔥 Firebase initialized');
      print('   Environment: ${EnvConfig.name}');
    }
  }

  /// Test Firebase connection with timeout
  static Future<bool> testConnection({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final completer = Completer<bool>();

      // Try to write and read a test document
      final testDoc = FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test');

      testDoc.set({'timestamp': DateTime.now().toIso8601String()}).then((_) {
        return testDoc.get();
      }).then((snapshot) {
        if (snapshot.exists) {
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      }).catchError((error) {
        if (kDebugMode) {
          print('Firebase connection error: $error');
        }
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      // Timeout handling
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          if (kDebugMode) {
            print('Firebase connection timeout');
          }
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Firebase connection test failed: $e');
      }
      return false;
    }
  }

  static FirebaseOptions _getFirebaseOptions() {
    switch (EnvConfig.current) {
      case AppEnvironment.local:
        // Demo project for emulator
        // API key must be in valid Firebase format (AIzaSy... 39 chars)
        // The demo- prefix project allows any valid-format API key
        // databaseURL uses standard format: projectId-default-rtdb
        return const FirebaseOptions(
          apiKey: 'AIzaSyDemoKeyForLocalEmulatorTesting123',
          appId: '1:123456789:web:abc123def456',
          messagingSenderId: '123456789',
          projectId: 'demo-shuttle-tracker',
          databaseURL: 'http://localhost:9000?ns=demo-shuttle-tracker-default-rtdb',
        );

      case AppEnvironment.dev:
        // TODO: Add real Firebase dev project credentials
        // Create a new Firebase project for development
        return const FirebaseOptions(
          apiKey: 'YOUR_DEV_API_KEY',
          appId: 'YOUR_DEV_APP_ID',
          messagingSenderId: 'YOUR_DEV_SENDER_ID',
          projectId: 'shuttle-tracker-dev',
        );

      case AppEnvironment.prod:
        // TODO: Add real Firebase prod project credentials
        // Create a new Firebase project for production
        return const FirebaseOptions(
          apiKey: 'YOUR_PROD_API_KEY',
          appId: 'YOUR_PROD_APP_ID',
          messagingSenderId: 'YOUR_PROD_SENDER_ID',
          projectId: 'shuttle-tracker-prod',
        );
    }
  }

  static Future<void> _connectToEmulators() async {
    final host = EnvConfig.emulatorHost;

    // Connect to Firestore emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, EnvConfig.firestorePort);

    // Connect to Auth emulator
    await FirebaseAuth.instance.useAuthEmulator(host, EnvConfig.authPort);

    // Connect to Realtime Database emulator
    FirebaseDatabase.instance.useDatabaseEmulator(host, EnvConfig.realtimeDbPort);

    if (kDebugMode) {
      print('🔥 Connected to Firebase Emulators');
      print('   - Firestore: $host:${EnvConfig.firestorePort}');
      print('   - Auth: $host:${EnvConfig.authPort}');
      print('   - Realtime DB: $host:${EnvConfig.realtimeDbPort}');
      print('   - UI: http://localhost:${EnvConfig.emulatorUiPort}');
    }
  }
}
