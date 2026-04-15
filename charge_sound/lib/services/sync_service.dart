import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sound_event.dart';
import '../models/sound_item.dart';
import 'supabase_service.dart';

class SyncService {
  const SyncService();

  SupabaseClient? get _client => SupabaseService.client;

  String? get _userId => _client?.auth.currentUser?.id;

  Future<void> pushSounds({
    required List<SoundItem> items,
    required bool recordings,
  }) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return;
    for (final item in items) {
      final mapped = <String, dynamic>{
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'source': item.source.name,
        'local_path': item.path,
        'duration_ms': item.duration.inMilliseconds,
        'category': item.category,
        'metadata': item.toJson(),
      };
      await client.from('sounds').upsert(mapped, onConflict: 'id');
      if (!item.path.startsWith('assets/') && File(item.path).existsSync()) {
        final bucket = recordings ? 'recordings' : 'user-files';
        final objectPath = '$userId/${item.id}${_extension(item.path)}';
        final bytes = await File(item.path).readAsBytes();
        await client.storage
            .from(bucket)
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        await client
            .from('sounds')
            .update({
              'storage_bucket': bucket,
              'storage_path': objectPath,
            })
            .eq('id', item.id);
      }
    }
  }

  Future<List<SoundItem>> pullSounds({required bool recordings}) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return const [];
    final source = recordings ? 'recording' : 'file';
    final rows = await client
        .from('sounds')
        .select('metadata')
        .eq('user_id', userId)
        .eq('source', source);
    return rows
        .map((e) => SoundItem.fromJson(Map<String, dynamic>.from(e['metadata'])))
        .toList();
  }

  Future<void> pushEventAssignments(
    Map<SoundEventType, SoundItem?> map,
  ) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return;
    for (final entry in map.entries) {
      final sound = entry.value;
      if (sound == null) continue;
      await client.from('event_assignments').upsert({
        'user_id': userId,
        'event_type': entry.key.name,
        'sound_data': sound.toJson(),
      }, onConflict: 'user_id,event_type');
    }
  }

  Future<Map<SoundEventType, SoundItem?>> pullEventAssignments() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) {
      return {for (final e in SoundEventType.values) e: null};
    }
    final rows = await client
        .from('event_assignments')
        .select('event_type,sound_data')
        .eq('user_id', userId);
    final out = <SoundEventType, SoundItem?>{
      for (final e in SoundEventType.values) e: null,
    };
    for (final row in rows) {
      final eventType = SoundEventType.values.byName(row['event_type'] as String);
      out[eventType] =
          SoundItem.fromJson(Map<String, dynamic>.from(row['sound_data']));
    }
    return out;
  }

  Future<void> pushTrimOverrides(Map<String, SoundItem> map) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return;
    for (final item in map.values) {
      await client.from('trim_overrides').upsert({
        'user_id': userId,
        'sound_id': item.id,
        'trim_start_ms': item.trimStart?.inMilliseconds,
        'trim_end_ms': item.trimEnd?.inMilliseconds,
        'fade_in_ms': item.fadeIn.inMilliseconds,
        'fade_out_ms': item.fadeOut.inMilliseconds,
      }, onConflict: 'user_id,sound_id');
    }
  }

  Future<void> pushDeviceSettings({
    required bool serviceEnabled,
    required double batteryThreshold,
    required String themeMode,
  }) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return;
    await client.from('device_settings').upsert({
      'user_id': userId,
      'service_enabled': serviceEnabled,
      'battery_threshold': batteryThreshold,
      'theme_mode': themeMode,
    });
  }
}

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return '.m4a';
  return path.substring(dot);
}
