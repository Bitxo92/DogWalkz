import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase credentials to be used in the app.
/// This class retrieves the Supabase URL and Anon Key from environment variables.
class SupabaseCredentials {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
