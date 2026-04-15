import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tagsPrefsKey = 'tags_list_v1';

class SoundTag {
  const SoundTag({
    required this.id,
    required this.name,
    this.color,
  });

  final String id;
  final String name;
  final String? color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (color != null) 'color': color,
      };

  factory SoundTag.fromJson(Map<String, dynamic> json) {
    return SoundTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
    );
  }
}

final tagsProvider =
    NotifierProvider<TagsNotifier, List<SoundTag>>(TagsNotifier.new);

class TagsNotifier extends Notifier<List<SoundTag>> {
  @override
  List<SoundTag> build() {
    Future.microtask(_load);
    return const [];
  }

  Future<void> add({
    required String name,
    String? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    state = [SoundTag(id: id, name: trimmed, color: color), ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [...state.where((e) => e.id != id)];
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tagsPrefsKey);
    if (raw == null) return;
    try {
      final jsonList = jsonDecode(raw) as List<dynamic>;
      state = jsonList
          .map((e) => SoundTag.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tagsPrefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }
}
