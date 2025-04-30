import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  User? get currentUser => _supabase.auth.currentUser; //get current user
  AuthRepository() : _supabase = Supabase.instance.client;

  /// Signs up a new user with email and password.
  /// Also creates a user profile in the 'users' table.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Check if the email is already registered
      final profileExists =
          await _supabase
              .from('users')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (profileExists != null) {
        throw AuthException('Email already registered');
      }

      // Create authentication user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone},
      );

      if (authResponse.user == null) {
        throw AuthException('User creation failed.');
      }

      // Insert user data into the 'users' table
      await _supabase.from('users').upsert({
        'id': authResponse.user!.id,
        'email': email,
        'username': name,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      });

      return authResponse;
    } on PostgrestException catch (e) {
      throw AuthException('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw AuthException('Auth error: ${e.message}');
    } catch (e) {
      throw AuthException('Unexpected error: ${e.toString()}');
    }
  }

  /// Signs in an existing user with email and password.
  /// Returns an AuthResponse object containing user information.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return authResponse;
    } on AuthException catch (e) {
      throw AuthException('Login failed: ${e.message}');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthException('Logout failed: ${e.message}');
    }
  }
}
