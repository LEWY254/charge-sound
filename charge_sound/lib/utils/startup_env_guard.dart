import '../services/supabase_service.dart';

class StartupEnvGuard {
  const StartupEnvGuard._();

  static List<String> missingVars() {
    final missing = <String>[];
    if (const String.fromEnvironment('SENTRY_DSN').isEmpty) {
      missing.add('SENTRY_DSN');
    }
    missing.addAll(SupabaseService.missingEnvVars());
    return missing;
  }

  static void enforce({required bool strict}) {
    final missing = missingVars();
    if (missing.isEmpty) return;
    final msg = 'Missing required startup env vars: ${missing.join(', ')}';
    if (strict) {
      throw StateError(msg);
    }
    // In non-strict mode, proceed silently (no debug logs in release builds).
  }
}
