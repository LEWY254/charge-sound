import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meme_sounds.dart';
import '../models/sound_event.dart';
import '../models/sound_item.dart';
import 'sync_provider.dart';

const _eventConfigKey = 'event_config';

final eventConfigProvider =
    NotifierProvider<EventConfigNotifier, Map<SoundEventType, SoundItem?>>(
        EventConfigNotifier.new);

class EventConfigNotifier extends Notifier<Map<SoundEventType, SoundItem?>> {
  @override
  Map<SoundEventType, SoundItem?> build() {
    _loadSaved();
    return {for (final e in SoundEventType.values) e: null};
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventConfigKey);
    if (raw == null) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final newState = <SoundEventType, SoundItem?>{};
      for (final eventType in SoundEventType.values) {
        final v = map[eventType.name];
        if (v == null) {
          newState[eventType] = null;
          continue;
        }
        if (v is String) {
          final matches = allMemeSounds.where((s) => s.id == v);
          newState[eventType] =
              matches.isEmpty ? null : matches.first;
        } else if (v is Map) {
          newState[eventType] =
              SoundItem.fromJson(Map<String, dynamic>.from(v));
        } else {
          newState[eventType] = null;
        }
      }
      state = newState;
      await _pullRemote();
    } catch (_) {}
  }

  Future<void> assignSound(SoundEventType event, SoundItem sound) async {
    state = {...state, event: sound};
    await _persist();
  }

  Future<void> removeSound(SoundEventType event) async {
    state = {...state, event: null};
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, dynamic>{};
    for (final entry in state.entries) {
      final s = entry.value;
      if (s == null) {
        out[entry.key.name] = null;
      } else {
        out[entry.key.name] = s.toJson();
      }
    }
    await prefs.setString(_eventConfigKey, jsonEncode(out));
    await ref.read(syncServiceProvider).pushEventAssignments(state);
  }

  Future<void> _pullRemote() async {
    final remote = await ref.read(syncServiceProvider).pullEventAssignments();
    state = {
      for (final e in SoundEventType.values)
        e: remote[e] ?? state[e],
    };
  }
}
