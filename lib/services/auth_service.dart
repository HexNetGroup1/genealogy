import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_initializer.dart';

class AuthService {
  final SupabaseClient _client = SupabaseInitializer.client;

  /// Returns the current user if logged in.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
