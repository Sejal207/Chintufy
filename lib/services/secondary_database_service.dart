import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class SecondaryDatabaseService {
  static FirebaseApp? _secondaryApp;
  static late final FirebaseDatabase _database;
  static bool _initialized = false;
  static const String _databasePath = 'rfid_uids';

  static final SecondaryDatabaseService _instance = SecondaryDatabaseService._internal();
  
  factory SecondaryDatabaseService() {
    if (!_initialized) {
      throw Exception('SecondaryDatabaseService not initialized. Call initialize() first.');
    }
    return _instance;
  }

  SecondaryDatabaseService._internal();

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('SecondaryDatabaseService already initialized');
      return;
    }

    try {
      // Initialize secondary Firebase app
      _secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCvw01JD80DYqolRLmnQeykuOGfjtILVfo',
          appId: '1:497205779670:android:7541f29873a647f0bffd77',
          messagingSenderId: '497205779670',
          projectId: 'bloodbanksystem-70840',
          databaseURL: 'https://bloodbanksystem-70840-default-rtdb.firebaseio.com',
          storageBucket: 'bloodbanksystem-70840.firebasestorage.app'
        ),
      );
      
      // Initialize database instance
      _database = FirebaseDatabase.instanceFor(app: _secondaryApp!);
      
      // Enable persistence for offline support
      _database.setPersistenceEnabled(true);
      
      // Keep rfid_uids synced (don't await void method)
      _database.ref(_databasePath).keepSynced(true);
      
      _initialized = true;
      debugPrint('Secondary Firebase initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing secondary Firebase: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
      rethrow;
    }
  }

  static bool get isInitialized => _initialized;

  Stream<Map<String, dynamic>> getRealtimeData(String path) {
    _checkInitialization();
    
    return _database.ref(path).onValue.map((event) {
      final snapshot = event.snapshot;
      
      if (!snapshot.exists || snapshot.value == null) {
        return <String, dynamic>{};
      }
      
      try {
        if (snapshot.value is Map) {
          return Map<String, dynamic>.from(snapshot.value as Map);
        } else {
          debugPrint('Unexpected data format: ${snapshot.value.runtimeType}');
          return <String, dynamic>{};
        }
      } catch (e, stackTrace) {
        debugPrint('Error parsing data at $path: $e');
        debugPrint('Stack trace: $stackTrace');
        return <String, dynamic>{};
      }
    }).handleError((error) {
      debugPrint('Database error for path $path: $error');
      return <String, dynamic>{};
    });
  }

  Future<bool> checkConnection() async {
    _checkInitialization();
    
    try {
      final snapshot = await _database.ref('.info/connected').get();
      return snapshot.value == true;
    } catch (e) {
      debugPrint('Database connection error: $e');
      return false;
    }
  }

  void _checkInitialization() {
    if (!_initialized) {
      throw StateError('SecondaryDatabaseService not initialized. Call initialize() first.');
    }
  }

  Future<void> dispose() async {
    if (_initialized && _secondaryApp != null) {
      await _secondaryApp!.delete();
      _initialized = false;
      debugPrint('SecondaryDatabaseService disposed');
    }
  }
}