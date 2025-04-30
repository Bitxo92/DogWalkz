import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  factory SupabaseManager() => _instance;
  SupabaseManager._internal();
  User? get currentUser => _client.auth.currentUser;
  late final SupabaseClient _client;
  bool _isInitialized = false;

  /// Initializes the Supabase client with environment variables
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Validate environment variables before initialization
      _validateEnvironment();

      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        storageOptions: const StorageClientOptions(),
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      if (kDebugMode) {
        print('Supabase initialized successfully');
      }
    } catch (e, stackTrace) {
      throw SupabaseInitializationException(
        'Failed to initialize Supabase: $e',
        stackTrace,
      );
    }
  }

  /// Validates that required environment variables are present
  void _validateEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || key.isEmpty) {
      throw const SupabaseConfigurationException(
        'Missing Supabase configuration. '
        'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are provided.',
      );
    }
  }

  /// Returns the Supabase client instance
  SupabaseClient get client {
    if (!_isInitialized) {
      throw SupabaseNotInitializedException(
        'Supabase has not been initialized. Call initialize() first.',
      );
    }
    return _client;
  }

  /// Signs in a user with the given email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw SupabaseAuthException(e.message);
    }
  }

  /// Signs up a new user with the given email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          ...userMetadata,
          'last_sign_in_at': DateTime.now().toIso8601String(),
        },
      );
    } on AuthException catch (e) {
      throw SupabaseAuthException(e.message);
    }
  }

  /// Signs out the current user.
  /// This method clears the user's session and revokes the access token.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw SupabaseAuthException(e.message);
    }
  }

  SupabaseQueryBuilder from(String table) {
    return _client.from(table);
  }

  /// Uploads a file to the specified bucket and path.
  /// [bucket] is the name of the storage bucket.
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List file,
  }) async {
    try {
      final response = await _client.storage
          .from(bucket)
          .uploadBinary(path, file);
      return response;
    } on StorageException catch (e) {
      throw SupabaseStorageException(e.message);
    }
  }
}

/// Custom exceptions for Supabase operations-----------------------------------
class SupabaseConfigurationException implements Exception {
  final String message;
  const SupabaseConfigurationException(this.message);
}

class SupabaseInitializationException implements Exception {
  final String message;
  final StackTrace stackTrace;
  SupabaseInitializationException(this.message, this.stackTrace);
}

class SupabaseNotInitializedException implements Exception {
  final String message;
  SupabaseNotInitializedException(this.message);
}

class SupabaseAuthException implements Exception {
  final String message;
  SupabaseAuthException(this.message);
}

class SupabaseStorageException implements Exception {
  final String message;
  SupabaseStorageException(this.message);
}
