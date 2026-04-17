import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sound_item.dart';
import 'supabase_service.dart';

class MarketplaceSound {
  const MarketplaceSound({
    required this.id,
    required this.name,
    required this.slug,
    required this.packName,
    required this.storageBucket,
    required this.storagePath,
    required this.durationMs,
    required this.category,
    required this.tags,
    required this.licenseLabel,
    required this.licenseUrl,
    required this.creatorName,
    required this.sourceAttribution,
    required this.sourceProvider,
    required this.previewPath,
  });

  final String id;
  final String name;
  final String slug;
  final String packName;
  final String storageBucket;
  final String storagePath;
  final int durationMs;
  final String category;
  final List<String> tags;
  final String licenseLabel;
  final String licenseUrl;
  final String creatorName;
  final String sourceAttribution;
  final String sourceProvider;
  final String? previewPath;
}

class MarketplaceService {
  const MarketplaceService._();

  static SupabaseClient? get _client => SupabaseService.client;
  static const String marketplaceBucket = 'meme-sounds';

  static Future<List<MarketplaceSound>> fetchSounds({
    String? searchQuery,
    String? category,
    int? limit,
  }) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('meme_sound_metadata')
        .select('file_name, display_name, category, tags')
        .order('display_name');
    final normalizedCategory = category?.trim().toLowerCase();
    final normalizedQuery = searchQuery?.trim().toLowerCase() ?? '';
    var sounds = rows
        .map((raw) => _fromMetadataRow(Map<String, dynamic>.from(raw)))
        .where((s) => s.storagePath.toLowerCase().endsWith('.mp3'))
        .toList();

    if (normalizedCategory != null &&
        normalizedCategory.isNotEmpty &&
        normalizedCategory != 'all') {
      sounds = sounds.where((s) => s.category == normalizedCategory).toList();
    }

    if (normalizedQuery.isNotEmpty) {
      sounds = sounds.where((sound) {
        final haystack = [
          sound.name,
          sound.packName,
          sound.category,
          sound.licenseLabel,
          ...sound.tags,
        ].join(' ').toLowerCase();
        return haystack.contains(normalizedQuery);
      }).toList();
    }

    if (limit != null && limit > 0 && sounds.length > limit) {
      sounds = sounds.take(limit).toList();
    }
    return sounds;
  }

  static Future<List<String>> fetchCategories() async {
    final rows = await fetchSounds();
    final categories = <String>{};
    for (final row in rows) {
      final category = row.category.trim();
      if (category.isNotEmpty) categories.add(category);
    }
    return categories.toList()..sort();
  }

  static SoundItem toSoundItem(MarketplaceSound sound) {
    return SoundItem(
      id: 'market_${sound.id}',
      name: sound.name,
      path: buildPublicUrl(
        bucket: sound.storageBucket,
        path: sound.storagePath,
      ),
      duration: Duration(milliseconds: sound.durationMs),
      source: SoundSource.preset,
      category: sound.category,
      createdAt: DateTime.now(),
      tags: sound.tags,
    );
  }

  static String buildPublicUrl({
    required String bucket,
    required String path,
  }) {
    final client = _client;
    if (client != null) {
      return client.storage.from(bucket).getPublicUrl(path);
    }
    final base = SupabaseService.url;
    return '$base/storage/v1/object/public/$bucket/$path';
  }

  static MarketplaceSound _fromMetadataRow(Map<String, dynamic> row) {
    final fileName = row['file_name'] as String;
    final cleanName = fileName.replaceAll('.mp3', '');
    final normalized = cleanName
        .replaceAll('_', '-')
        .replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '')
        .toLowerCase();
    final dbTags = (row['tags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final tags = dbTags;
    final category =
        (row['category'] as String?)?.trim().toLowerCase().isNotEmpty == true
            ? (row['category'] as String).trim().toLowerCase()
            : 'market';
    final displayName = ((row['display_name'] as String?) ?? '')
        .trim();

    return MarketplaceSound(
      id: fileName,
      name: displayName.isEmpty ? cleanName.replaceAll('-', ' ').trim() : displayName,
      slug: normalized,
      packName: 'Meme Sounds',
      storageBucket: marketplaceBucket,
      storagePath: fileName,
      durationMs: 0,
      category: category,
      tags: tags,
      licenseLabel: 'Royalty Free',
      licenseUrl: '',
      creatorName: '',
      sourceAttribution: 'From the community meme sound catalog.',
      sourceProvider: 'Marketplace',
      previewPath: fileName,
    );
  }
}
