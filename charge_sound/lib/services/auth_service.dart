import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  const AuthService();

  SupabaseClient? get _client => SupabaseService.client;

  Future<void> ensureAnonymousSession() async {
    final client = _client;
    if (client == null) return;
    if (client.auth.currentUser != null) return;
    await client.auth.signInAnonymously();
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return null;
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return null;
    return client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse?> signInWithGoogle() async {
    final client = _client;
    if (client == null) return null;
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final account = await googleSignIn.authenticate();
    final auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) return null;
    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }
}
