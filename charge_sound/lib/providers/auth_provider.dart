import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return const AuthService();
});

final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authServiceProvider).ensureAnonymousSession();
});

final authStateProvider =
    StreamProvider<AuthState>((ref) async* {
  final client = SupabaseService.client;
  if (client == null) {
    yield AuthState(AuthChangeEvent.initialSession, null);
    return;
  }
  yield AuthState(AuthChangeEvent.initialSession, client.auth.currentSession);
  yield* client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (state) => state.session?.user,
        orElse: () => null,
      );
});
