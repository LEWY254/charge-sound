enum SoundSource { file, meme, recording, preset }

class SoundItem {
  final String id;
  final String name;
  final String path;
  final Duration duration;
  final SoundSource source;
  final String? category;
  final DateTime? createdAt;
  /// Non-destructive trim: playback window [trimStart, trimEnd). Null = full clip.
  final Duration? trimStart;
  final Duration? trimEnd;
  final List<String> tags;
  final String? folderId;
  final bool isFavorite;
  final Duration fadeIn;
  final Duration fadeOut;

  const SoundItem({
    required this.id,
    required this.name,
    required this.path,
    required this.duration,
    required this.source,
    this.category,
    this.createdAt,
    this.trimStart,
    this.trimEnd,
    this.tags = const [],
    this.folderId,
    this.isFavorite = false,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
  });

  /// Effective playback duration when trim is applied.
  Duration get effectiveDuration {
    final start = trimStart ?? Duration.zero;
    final end = trimEnd ?? duration;
    final len = end - start;
    return len.isNegative ? duration : len;
  }

  String get durationLabel {
    final d = effectiveDuration;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get sourceLabel => switch (source) {
        SoundSource.file => 'My Files',
        SoundSource.meme => 'Meme Sound',
        SoundSource.recording => 'Recording',
        SoundSource.preset => 'Preset',
      };

  bool get hasTrim {
    final s = trimStart;
    final e = trimEnd;
    if (s != null && s > Duration.zero) return true;
    if (e != null && e < duration) return true;
    return false;
  }

  SoundItem copyWith({
    String? id,
    String? name,
    String? path,
    Duration? duration,
    SoundSource? source,
    String? category,
    DateTime? createdAt,
    Duration? trimStart,
    Duration? trimEnd,
    List<String>? tags,
    String? folderId,
    bool? isFavorite,
    Duration? fadeIn,
    Duration? fadeOut,
    bool clearTrim = false,
    bool clearFolder = false,
  }) {
    return SoundItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      trimStart: clearTrim ? null : (trimStart ?? this.trimStart),
      trimEnd: clearTrim ? null : (trimEnd ?? this.trimEnd),
      tags: tags ?? this.tags,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      isFavorite: isFavorite ?? this.isFavorite,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'durationMs': duration.inMilliseconds,
        'source': source.name,
        if (category != null) 'category': category,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (trimStart != null) 'trimStartMs': trimStart!.inMilliseconds,
        if (trimEnd != null) 'trimEndMs': trimEnd!.inMilliseconds,
        if (tags.isNotEmpty) 'tags': tags,
        if (folderId != null) 'folderId': folderId,
        if (isFavorite) 'isFavorite': true,
        if (fadeIn > Duration.zero) 'fadeInMs': fadeIn.inMilliseconds,
        if (fadeOut > Duration.zero) 'fadeOutMs': fadeOut.inMilliseconds,
      };

  factory SoundItem.fromJson(Map<String, dynamic> json) {
    return SoundItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      source: SoundSource.values.byName(json['source'] as String),
      category: json['category'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      trimStart: json['trimStartMs'] != null
          ? Duration(milliseconds: json['trimStartMs'] as int)
          : null,
      trimEnd: json['trimEndMs'] != null
          ? Duration(milliseconds: json['trimEndMs'] as int)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      folderId: json['folderId'] as String?,
      isFavorite: json['isFavorite'] == true,
      fadeIn: Duration(milliseconds: (json['fadeInMs'] as int?) ?? 0),
      fadeOut: Duration(milliseconds: (json['fadeOutMs'] as int?) ?? 0),
    );
  }
}
