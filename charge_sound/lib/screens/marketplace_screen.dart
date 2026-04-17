import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/audio_player_provider.dart';
import '../providers/recordings_provider.dart';
import '../services/marketplace_analytics_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/assign_to_event_dialog.dart';
import '../widgets/royalty_free_terms_sheet.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _selectedTag = 'all';
  String _selectedDurationBand = 'all';
  bool _loading = true;
  String? _error;
  List<String> _categories = const [];
  List<MarketplaceSound> _sounds = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await MarketplaceService.fetchCategories();
      final sounds = await MarketplaceService.fetchSounds();
      if (!mounted) return;
      setState(() {
        _categories = ['all', ...categories];
        _sounds = sounds;
        _loading = false;
      });
      MarketplaceAnalyticsService.track(
        'catalog_view',
        payload: {'items': sounds.length, 'categories': categories.length},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _addSound(MarketplaceSound sound) async {
    final item = MarketplaceService.toSoundItem(sound);
    final existing = ref.read(recordingsProvider);
    final alreadyAdded = existing.any((entry) => entry.id == item.id);
    if (alreadyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This sound is already in your library.')),
      );
      return;
    }
    await ref.read(recordingsProvider.notifier).add(item);
    MarketplaceAnalyticsService.track(
      'add_to_library',
      payload: {'sound_id': sound.id, 'category': sound.category},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${sound.name}" to your sounds.')),
    );
  }

  List<MarketplaceSound> get _filteredSounds {
    final query = _searchController.text.trim().toLowerCase();
    final queryTokens = query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    final filtered = _sounds.where((sound) {
      final categoryMatch =
          _selectedCategory == 'all' || sound.category == _selectedCategory;
      if (!categoryMatch) return false;

      final tagMatch =
          _selectedTag == 'all' || sound.tags.any((tag) => tag == _selectedTag);
      if (!tagMatch) return false;

      if (!_durationBandMatch(sound)) return false;

      if (queryTokens.isEmpty) return true;
      final haystack = [
        sound.name.toLowerCase(),
        sound.packName.toLowerCase(),
        sound.category.toLowerCase(),
        sound.licenseLabel.toLowerCase(),
        ...sound.tags.map((t) => t.toLowerCase()),
      ];
      return queryTokens.every(
        (token) => haystack.any((field) => field.contains(token)),
      );
    }).toList();

    filtered.sort((a, b) => _scoreSound(b, queryTokens) - _scoreSound(a, queryTokens));
    return filtered;
  }

  List<String> get _topTags {
    final counts = <String, int>{};
    for (final sound in _sounds) {
      for (final tag in sound.tags) {
        if (tag.trim().isEmpty) continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(12).map((e) => e.key).toList();
  }

  bool _durationBandMatch(MarketplaceSound sound) {
    if (_selectedDurationBand == 'all' || sound.durationMs <= 0) return true;
    if (_selectedDurationBand == 'short') return sound.durationMs < 4000;
    if (_selectedDurationBand == 'medium') {
      return sound.durationMs >= 4000 && sound.durationMs < 10000;
    }
    return sound.durationMs >= 10000;
  }

  int _scoreSound(MarketplaceSound sound, List<String> queryTokens) {
    if (queryTokens.isEmpty) return 0;
    var score = 0;
    final name = sound.name.toLowerCase();
    final category = sound.category.toLowerCase();
    final tags = sound.tags.map((t) => t.toLowerCase()).toList();
    final pack = sound.packName.toLowerCase();

    for (final token in queryTokens) {
      if (name == token) score += 200;
      if (name.startsWith(token)) score += 60;
      if (name.contains(token)) score += 35;
      if (category == token) score += 50;
      if (category.contains(token)) score += 20;
      if (pack.contains(token)) score += 15;
      if (tags.any((t) => t == token)) score += 45;
      if (tags.any((t) => t.contains(token))) score += 20;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sounds = _filteredSounds;
    final currentSoundId = ref.watch(
      audioPlayerProvider.select((state) => state.currentSoundId),
    );
    final isPlayerPlaying = ref.watch(
      audioPlayerProvider.select((state) => state.isPlaying),
    );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Marketplace'),
              actions: [
                IconButton(
                  onPressed: () => showRoyaltyFreeTermsSheet(context),
                  icon: const Icon(LucideIcons.scale),
                  tooltip: 'Royalty-free terms',
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(LucideIcons.refreshCcw),
                  tooltip: 'Refresh',
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search royalty-free sounds',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      label: Text(category == 'all' ? 'All' : category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_topTags.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: _selectedTag == 'all',
                      onSelected: (_) => setState(() => _selectedTag = 'all'),
                      label: const Text('All tags'),
                    ),
                  ),
                  for (final tag in _topTags)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: _selectedTag == tag,
                        onSelected: (_) => setState(() => _selectedTag = tag),
                        label: Text(tag),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Duration:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedDurationBand,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'short', child: Text('Short')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'long', child: Text('Long')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedDurationBand = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Failed to load marketplace.\n$_error',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: cs.error),
                          ),
                        ),
                      )
                    : sounds.isEmpty
                        ? Center(
                            child: Text(
                              'No sounds match your filters.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            itemCount: sounds.length,
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            itemBuilder: (context, index) {
                              final sound = sounds[index];
                              final previewItem =
                                  MarketplaceService.toSoundItem(sound);
                              final isActive = currentSoundId == previewItem.id;
                              final isPlaying = isActive && isPlayerPlaying;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    sound.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  subtitle: Text(
                                    sound.category,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  leading: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      MarketplaceAnalyticsService.track(
                                        'preview_play',
                                        payload: {
                                          'sound_id': sound.id,
                                          'category': sound.category,
                                        },
                                      );
                                      ref
                                          .read(audioPlayerProvider.notifier)
                                          .togglePlay(previewItem);
                                    },
                                    icon: Icon(
                                      isPlaying
                                          ? LucideIcons.pause
                                          : LucideIcons.play,
                                      size: 18,
                                    ),
                                    tooltip: 'Preview',
                                  ),
                                  trailing: SizedBox(
                                    width: 124,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FilledButton.tonal(
                                          onPressed: () => _addSound(sound),
                                          style: FilledButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                          ),
                                          child: const Text('Add'),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: 'More actions',
                                          onSelected: (value) async {
                                            if (value == 'license') {
                                              _showLicenseInfo(
                                                context: context,
                                                sound: sound,
                                              );
                                              return;
                                            }
                                            if (value == 'assign') {
                                              await _addSound(sound);
                                              if (!mounted) return;
                                              await showAssignToEventDialog(
                                                this.context,
                                                ref,
                                                MarketplaceService.toSoundItem(sound),
                                              );
                                              MarketplaceAnalyticsService.track(
                                                'assign_to_event',
                                                payload: {'sound_id': sound.id},
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'license',
                                              child: Text('License'),
                                            ),
                                            PopupMenuItem(
                                              value: 'assign',
                                              child: Text('Add and assign'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showLicenseInfo({
    required BuildContext context,
    required MarketplaceSound sound,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sound.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('License: ${sound.licenseLabel}'),
            if (sound.creatorName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Creator: ${sound.creatorName}'),
            ],
            if (sound.sourceProvider.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Source: ${sound.sourceProvider}'),
            ],
            if (sound.sourceAttribution.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                sound.sourceAttribution,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (sound.licenseUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                sound.licenseUrl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
