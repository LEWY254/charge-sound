import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  const SupabaseService._();

  static String get url => const String.fromEnvironment('SUPABASE_URL');
  static String get anonKey => const String.fromEnvironment('SUPABASE_ANON_KEY');

  static List<String> missingEnvVars() {
    final missing = <String>[];
    if (url.isEmpty) missing.add('SUPABASE_URL');
    if (anonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    return missing;
  }

  static Future<void> initialize({required bool strict}) async {
    final missing = missingEnvVars();
    if (missing.isNotEmpty) {
      if (strict) {
        throw StateError(
          'Missing required Supabase env vars: ${missing.join(', ')}',
        );
      }
      return;
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
