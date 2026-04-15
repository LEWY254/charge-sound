import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/sound_item.dart';
import '../services/supabase_service.dart';

/// Returns the public Supabase URL for a meme sound filename.
String memeSoundPublicUrl(String filename) {
  final base = SupabaseService.url;
  return '$base/storage/v1/object/public/meme-sounds/$filename';
}

/// Downloads and caches meme sounds from Supabase Storage.
/// Files are written to `<cacheDir>/meme_sounds/<filename>` and
/// re-used on subsequent calls without a network request.
class MemeSoundCacheService {
  static Future<Directory> _cacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/meme_sounds');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the local file path for [sound], downloading from Supabase if
  /// not already cached.
  Future<String> resolve(SoundItem sound) async {
    assert(sound.source == SoundSource.meme, 'Only meme sounds are cached');
    final filename = sound.path.split('/').last;
    final dir = await _cacheDir();
    final cached = File('${dir.path}/$filename');
    if (await cached.exists()) return cached.path;

    final url = memeSoundPublicUrl(filename);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download meme sound $filename: ${response.statusCode}');
    }
    await cached.writeAsBytes(response.bodyBytes);
    return cached.path;
  }

  /// Clears all cached meme sounds (e.g. on low storage).
  Future<void> clearCache() async {
    final dir = await _cacheDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

final memeSoundCacheServiceProvider = Provider<MemeSoundCacheService>(
  (_) => MemeSoundCacheService(),
);

/// Resolves a meme sound to its local cached path, downloading if necessary.
/// Returns the Supabase public URL directly if Supabase is not configured
/// (so just_audio can stream it instead).
final memeSoundPathProvider = FutureProvider.family<String, SoundItem>(
  (ref, sound) async {
    if (SupabaseService.url.isEmpty) {
      return memeSoundPublicUrl(sound.path.split('/').last);
    }
    return ref.read(memeSoundCacheServiceProvider).resolve(sound);
  },
);
