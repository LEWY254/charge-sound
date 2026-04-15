import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SharedPreferences key used by the native Android service to construct
/// meme-sound fallback URLs without the Flutter engine running.
const kSupabaseUrlPrefKey = 'flutter.supabase_url';

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
    if (url.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kSupabaseUrlPrefKey, url);
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
