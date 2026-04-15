import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sound_item.dart';
import 'sync_provider.dart';
import 'sound_trim_store_provider.dart';

const _prefsKey = 'recordings_list_v1';

final recordingsProvider =
    NotifierProvider<RecordingsNotifier, List<SoundItem>>(RecordingsNotifier.new);

class RecordingsNotifier extends Notifier<List<SoundItem>> {
  @override
  List<SoundItem> build() {
    Future.microtask(_load);
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => SoundItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = items;
      await _pullRemote();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
    await ref
        .read(syncServiceProvider)
        .pushSounds(items: state, recordings: true);
  }

  Future<void> _pullRemote() async {
    final remote = await ref
        .read(syncServiceProvider)
        .pullSounds(recordings: true);
    if (remote.isEmpty) return;
    final byId = {for (final s in state) s.id: s};
    for (final r in remote) {
      byId[r.id] = r;
    }
    state = byId.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(SoundItem item) async {
    state = [item, ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    SoundItem? item;
    for (final s in state) {
      if (s.id == id) {
        item = s;
        break;
      }
    }
    if (item != null &&
        !item.path.startsWith('assets/') &&
        item.source == SoundSource.recording) {
      try {
        final f = File(item.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await ref.read(soundTrimStoreProvider.notifier).remove(id);
    state = [...state.where((e) => e.id != id)];
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isFavorite: !s.isFavorite) else s,
    ];
    await _persist();
  }

  Future<void> rename(String id, String newName) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(name: newName) else s,
    ];
    final trim = ref.read(soundTrimStoreProvider)[id];
    if (trim != null) {
      await ref
          .read(soundTrimStoreProvider.notifier)
          .put(trim.copyWith(name: newName));
    }
    await _persist();
  }

  Future<void> updateItem(SoundItem updated) async {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    final trim = ref.read(soundTrimStoreProvider)[updated.id];
    if (trim != null) {
      await ref.read(soundTrimStoreProvider.notifier).put(updated);
    }
    await _persist();
  }
}
