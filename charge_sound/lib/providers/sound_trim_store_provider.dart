import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sound_item.dart';
import 'sync_provider.dart';

const _prefsKey = 'sound_trim_overrides';

final soundTrimStoreProvider =
    NotifierProvider<SoundTrimStoreNotifier, Map<String, SoundItem>>(
  SoundTrimStoreNotifier.new,
);

class SoundTrimStoreNotifier extends Notifier<Map<String, SoundItem>> {
  @override
  Map<String, SoundItem> build() {
    Future.microtask(() => _load());
    return {};
  }

  SoundItem resolve(SoundItem base) => state[base.id] ?? base;

  Future<void> put(SoundItem item) async {
    state = {...state, item.id: item};
    await _persist();
  }

  Future<void> remove(String id) async {
    if (!state.containsKey(id)) return;
    final next = Map<String, SoundItem>.from(state)..remove(id);
    state = next;
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final out = <String, SoundItem>{};
        for (final e in map.entries) {
          out[e.key] =
              SoundItem.fromJson(Map<String, dynamic>.from(e.value as Map));
        }
        state = {...out, ...state};
      } catch (_) {}
    }
    await _pullRemote();
  }

  Future<void> _pullRemote() async {
    final remote = await ref.read(syncServiceProvider).pullTrimOverrides();
    if (remote.isEmpty) return;
    // Merge remote trim/fade into local items, preserving all other fields.
    final merged = Map<String, SoundItem>.from(state);
    for (final entry in remote.entries) {
      final existing = merged[entry.key];
      if (existing != null) {
        merged[entry.key] = existing.copyWith(
          trimStart: entry.value.trimStart,
          trimEnd: entry.value.trimEnd,
          fadeIn: entry.value.fadeIn,
          fadeOut: entry.value.fadeOut,
        );
      }
    }
    state = merged;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{
      for (final e in state.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_prefsKey, jsonEncode(encoded));
    await ref.read(syncServiceProvider).pushTrimOverrides(state);
  }
}
