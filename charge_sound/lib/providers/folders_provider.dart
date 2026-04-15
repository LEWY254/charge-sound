import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _foldersPrefsKey = 'folders_list_v1';

class SoundFolder {
  const SoundFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
  });

  final String id;
  final String name;
  final String? parentFolderId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (parentFolderId != null) 'parentFolderId': parentFolderId,
      };

  factory SoundFolder.fromJson(Map<String, dynamic> json) {
    return SoundFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
    );
  }
}

final foldersProvider =
    NotifierProvider<FoldersNotifier, List<SoundFolder>>(FoldersNotifier.new);

class FoldersNotifier extends Notifier<List<SoundFolder>> {
  @override
  List<SoundFolder> build() {
    Future.microtask(_load);
    return const [];
  }

  Future<void> add({
    required String name,
    String? parentFolderId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = [
      SoundFolder(
        id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
        name: trimmed,
        parentFolderId: parentFolderId,
      ),
      ...state,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [...state.where((f) => f.id != id && f.parentFolderId != id)];
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_foldersPrefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((e) => SoundFolder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _foldersPrefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }
}
