import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../audio/audio_processor.dart';
import '../config/feature_flags.dart';
import '../models/meme_sounds.dart';
import '../models/sound_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/recordings_provider.dart';
import '../providers/sound_trim_store_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/user_files_provider.dart';
import '../utils/app_audio_dirs.dart';
import '../utils/audio_duration_probe.dart';
import '../widgets/assign_to_event_dialog.dart';
import '../widgets/sound_tile.dart';
import 'audio_editor_screen.dart';
import 'import_url_screen.dart';
import 'marketplace_screen.dart';

Future<void> pickAndAddUserFile(
  BuildContext context,
  WidgetRef ref,
) async {
  const processor = AudioProcessor();
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const [
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'flac',
      'opus',
      '3gp',
    ],
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return;
  final f = result.files.first;
  final srcPath = f.path;
  if (srcPath == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file path.')),
      );
    }
    return;
  }
  try {
    final userDir = await ensureUserFilesDirectory();
    final safeName = f.name.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    final destPath =
        '${userDir.path}/user_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await File(srcPath).copy(destPath);
    final normalizedPath =
        '${userDir.path}/normalized_${DateTime.now().millisecondsSinceEpoch}_${p.basename(safeName)}';
    final normalized = await processor.normalizeVolume(destPath, normalizedPath);
    final finalPath = normalized ?? destPath;
    final duration = await probeAudioFileDuration(finalPath);
    final trim = await processor.autoDetectSilence(
      finalPath,
      fallbackDurationMs: duration.inMilliseconds,
    );
    final baseName = p.basenameWithoutExtension(safeName);
    final item = SoundItem(
      id: 'userfile_${DateTime.now().millisecondsSinceEpoch}',
      name: baseName.isNotEmpty ? baseName : 'Imported sound',
      path: finalPath,
      duration: duration,
      source: SoundSource.file,
      createdAt: DateTime.now(),
      trimStart: trim == null
          ? null
          : Duration(milliseconds: trim.trimStartMs),
      trimEnd: trim == null ? null : Duration(milliseconds: trim.trimEndMs),
    );
    await ref.read(userFilesProvider.notifier).add(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added “${item.name}”')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

class SoundLibraryScreen extends ConsumerStatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  ConsumerState<SoundLibraryScreen> createState() =>
      _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends ConsumerState<SoundLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  final Set<SoundSource> _sourceFilter = {...SoundSource.values};
  bool _favoritesOnly = false;
  double _maxDurationSeconds = 30;
  String? _selectedTagFilter;
  String? _selectedFolderFilterId;

  Future<String?> _promptForLabelName({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<String?> _pickTagFilter() async {
    var tags = ref.read(tagsProvider);
    var selected = _selectedTagFilter;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Filter by tag'),
          content: SizedBox(
            width: double.maxFinite,
            child: tags.isEmpty
                ? const Text('No tags yet. Create your first tag.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final tag in tags)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tag.name),
                          trailing: selected == tag.name
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => setInnerState(() => selected = tag.name),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = await _promptForLabelName(
                  title: 'New tag',
                  label: 'Tag name',
                );
                if (name == null) return;
                await ref.read(tagsProvider.notifier).add(name: name);
                tags = ref.read(tagsProvider);
                setInnerState(() {
                  selected = name;
                });
              },
              child: const Text('New Tag'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(ctx).pop(selected),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickFolderFilter() async {
    var folders = ref.read(foldersProvider);
    var selected = _selectedFolderFilterId;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Filter by folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: folders.isEmpty
                ? const Text('No folders yet. Create your first folder.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final folder in folders)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(folder.name),
                          trailing: selected == folder.id
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => setInnerState(() => selected = folder.id),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = await _promptForLabelName(
                  title: 'New folder',
                  label: 'Folder name',
                );
                if (name == null) return;
                await ref.read(foldersProvider.notifier).add(name: name);
                folders = ref.read(foldersProvider);
                final created = folders.firstWhere((f) => f.name == name);
                setInnerState(() {
                  selected = created.id;
                });
              },
              child: const Text('New Folder'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(ctx).pop(selected),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLabelManager(SoundItem sound) async {
    var tags = ref.read(tagsProvider);
    var folders = ref.read(foldersProvider);
    final selectedTags = Set<String>.from(sound.tags);
    String? selectedFolderId = sound.folderId;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text('Manage labels for "${sound.name}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in tags)
                        FilterChip(
                          label: Text(tag.name),
                          selected: selectedTags.contains(tag.name),
                          onSelected: (v) {
                            setInnerState(() {
                              if (v) {
                                selectedTags.add(tag.name);
                              } else {
                                selectedTags.remove(tag.name);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final name = await _promptForLabelName(
                        title: 'New tag',
                        label: 'Tag name',
                      );
                      if (name == null) return;
                      await ref.read(tagsProvider.notifier).add(name: name);
                      tags = ref.read(tagsProvider);
                      setInnerState(() {
                        selectedTags.add(name);
                      });
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Create tag'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Folder',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('No folder'),
                        selected: selectedFolderId == null,
                        onSelected: (_) {
                          setInnerState(() => selectedFolderId = null);
                        },
                      ),
                      for (final folder in folders)
                        ChoiceChip(
                          label: Text(folder.name),
                          selected: selectedFolderId == folder.id,
                          onSelected: (_) {
                            setInnerState(() => selectedFolderId = folder.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final name = await _promptForLabelName(
                        title: 'New folder',
                        label: 'Folder name',
                      );
                      if (name == null) return;
                      await ref.read(foldersProvider.notifier).add(name: name);
                      folders = ref.read(foldersProvider);
                      final created = folders.firstWhere((f) => f.name == name);
                      setInnerState(() {
                        selectedFolderId = created.id;
                      });
                    },
                    icon: const Icon(LucideIcons.folderPlus, size: 16),
                    label: const Text('Create folder'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;
    final updated = sound.copyWith(
      tags: selectedTags.toList()..sort(),
      folderId: selectedFolderId,
      clearFolder: selectedFolderId == null,
    );
    await _saveSoundMetadata(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated labels')),
    );
  }

  Future<void> _saveSoundMetadata(SoundItem updated) async {
    switch (updated.source) {
      case SoundSource.file:
        await ref.read(userFilesProvider.notifier).updateItem(updated);
      case SoundSource.recording:
        await ref.read(recordingsProvider.notifier).updateItem(updated);
      case SoundSource.meme:
      case SoundSource.preset:
        await ref.read(soundTrimStoreProvider.notifier).put(updated);
    }
  }

  Future<void> _openFiltersSheet({
    required int tagsCount,
    required int foldersCount,
    required Map<String, String> folderNameById,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sound Filters',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Favorites only'),
                      value: _favoritesOnly,
                      onChanged: (v) {
                        setState(() => _favoritesOnly = v);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final source in SoundSource.values)
                          FilterChip(
                            label: Text(source.name),
                            selected: _sourceFilter.contains(source),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _sourceFilter.add(source);
                                } else {
                                  _sourceFilter.remove(source);
                                }
                                if (_sourceFilter.isEmpty) {
                                  _sourceFilter.addAll(SoundSource.values);
                                }
                              });
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final selected = await _pickTagFilter();
                              if (selected == null) return;
                              setState(() => _selectedTagFilter = selected);
                              setSheetState(() {});
                            },
                            child: Text(
                              _selectedTagFilter == null
                                  ? 'Tag ($tagsCount)'
                                  : 'Tag: $_selectedTagFilter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedTagFilter != null)
                          IconButton(
                            tooltip: 'Clear tag filter',
                            onPressed: () {
                              setState(() => _selectedTagFilter = null);
                              setSheetState(() {});
                            },
                            icon: const Icon(LucideIcons.x),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final selected = await _pickFolderFilter();
                              if (selected == null) return;
                              setState(() => _selectedFolderFilterId = selected);
                              setSheetState(() {});
                            },
                            child: Text(
                              _selectedFolderFilterId == null
                                  ? 'Folder ($foldersCount)'
                                  : 'Folder: ${folderNameById[_selectedFolderFilterId] ?? 'Unknown'}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedFolderFilterId != null)
                          IconButton(
                            tooltip: 'Clear folder filter',
                            onPressed: () {
                              setState(() => _selectedFolderFilterId = null);
                              setSheetState(() {});
                            },
                            icon: const Icon(LucideIcons.x),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Max duration: ${_maxDurationSeconds.round()}s',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    Slider(
                      value: _maxDurationSeconds,
                      min: 1,
                      max: 60,
                      divisions: 59,
                      onChanged: (v) {
                        setState(() => _maxDurationSeconds = v);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _favoritesOnly = false;
                            _sourceFilter
                              ..clear()
                              ..addAll(SoundSource.values);
                            _selectedTagFilter = null;
                            _selectedFolderFilterId = null;
                            _maxDurationSeconds = 30;
                          });
                          setSheetState(() {});
                        },
                        child: const Text('Reset filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onTabControllerTick() {
    if (_tabController.indexIsChanging) return;
    ref.read(soundLibraryTabProvider.notifier).state = _tabController.index;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final tabCount = marketplaceEnabled ? 4 : 3;
    final initial = ref.read(soundLibraryTabProvider).clamp(0, tabCount - 1);
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initial,
    );
    _tabController.addListener(_onTabControllerTick);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(soundLibraryTabProvider, (prev, next) {
      final idx = next.clamp(0, _tabController.length - 1);
      if (_tabController.index != idx) {
        _tabController.animateTo(idx);
      }
    });

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tags = ref.watch(tagsProvider);
    final folders = ref.watch(foldersProvider);
    final folderNameById = {
      for (final folder in folders) folder.id: folder.name,
    };
    final marketTabIndex = marketplaceEnabled ? _tabController.length - 1 : -1;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Sound Library',
              style: tt.titleLarge?.copyWith(color: cs.onSurface),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                _tabController.index == marketTabIndex ? 64 : 164,
              ),
              child: Column(
                children: [
                  if (_tabController.index != marketTabIndex) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchBar(
                        hintText: 'Search sounds...',
                        leading: Icon(
                          LucideIcons.search,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor:
                            WidgetStateProperty.all(cs.surfaceContainerHighest),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        textStyle: WidgetStateProperty.all(tt.bodyMedium),
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                if (_favoritesOnly) 'Favorites',
                                if (_selectedTagFilter != null) 'Tag',
                                if (_selectedFolderFilterId != null) 'Folder',
                                '${_maxDurationSeconds.round()}s',
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _openFiltersSheet(
                              tagsCount: tags.length,
                              foldersCount: folders.length,
                              folderNameById: folderNameById,
                            ),
                            icon: const Icon(LucideIcons.slidersHorizontal, size: 16),
                            label: const Text('Filters'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: cs.onPrimaryContainer,
                        unselectedLabelColor: cs.onSurfaceVariant,
                        labelStyle: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: tt.labelLarge,
                        tabs: [
                          const Tab(text: 'Files'),
                          const Tab(text: 'Sounds'),
                          const Tab(text: 'Records'),
                          if (marketplaceEnabled) const Tab(text: 'Market'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MyFilesTab(
              searchQuery: _searchQuery,
              sourceFilter: _sourceFilter,
              favoritesOnly: _favoritesOnly,
              maxDuration: Duration(seconds: _maxDurationSeconds.round()),
              selectedTagFilter: _selectedTagFilter,
              selectedFolderFilterId: _selectedFolderFilterId,
              folderNameById: folderNameById,
              onManageLabels: _openLabelManager,
            ),
            _MemeSoundsTab(
              searchQuery: _searchQuery,
              sourceFilter: _sourceFilter,
              favoritesOnly: _favoritesOnly,
              maxDuration: Duration(seconds: _maxDurationSeconds.round()),
              selectedTagFilter: _selectedTagFilter,
              selectedFolderFilterId: _selectedFolderFilterId,
              folderNameById: folderNameById,
              onManageLabels: _openLabelManager,
            ),
            _RecordingsTab(
              searchQuery: _searchQuery,
              sourceFilter: _sourceFilter,
              favoritesOnly: _favoritesOnly,
              maxDuration: Duration(seconds: _maxDurationSeconds.round()),
              selectedTagFilter: _selectedTagFilter,
              selectedFolderFilterId: _selectedFolderFilterId,
              folderNameById: folderNameById,
              onManageLabels: _openLabelManager,
            ),
            if (marketplaceEnabled) const MarketplaceScreen(embedded: true),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => pickAndAddUserFile(context, ref),
            icon: const Icon(LucideIcons.filePlus),
            label: const Text('Add Sound'),
          );
        },
      ),
    );
  }
}

class _MemeSoundsTab extends ConsumerWidget {
  final String searchQuery;
  final Set<SoundSource> sourceFilter;
  final bool favoritesOnly;
  final Duration maxDuration;
  final String? selectedTagFilter;
  final String? selectedFolderFilterId;
  final Map<String, String> folderNameById;
  final Future<void> Function(SoundItem sound) onManageLabels;

  const _MemeSoundsTab({
    required this.searchQuery,
    required this.sourceFilter,
    required this.favoritesOnly,
    required this.maxDuration,
    required this.selectedTagFilter,
    required this.selectedFolderFilterId,
    required this.folderNameById,
    required this.onManageLabels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final overrides = ref.watch(soundTrimStoreProvider);
    final ap = ref.watch(audioPlayerProvider);
    if (!sourceFilter.contains(SoundSource.meme)) {
      return const SizedBox.shrink();
    }

    final filteredCategories = memeSoundCategories.map((cat) {
      if (searchQuery.isEmpty) return cat;
      final filtered = cat.sounds
          .where(
            (s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .where((s) => s.effectiveDuration <= maxDuration)
          .where((s) => !favoritesOnly || (overrides[s.id] ?? s).isFavorite)
          .where(
            (s) =>
                selectedTagFilter == null ||
                (overrides[s.id] ?? s).tags.contains(selectedTagFilter),
          )
          .where(
            (s) =>
                selectedFolderFilterId == null ||
                (overrides[s.id] ?? s).folderId == selectedFolderFilterId,
          )
          .toList();
      return MemeSoundCategory(name: cat.name, sounds: filtered);
    }).where((cat) => cat.sounds.isNotEmpty).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No sounds match your search.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filteredCategories.length,
      itemBuilder: (context, catIndex) {
        final category = filteredCategories[catIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category.name.toUpperCase(),
                style: tt.labelLarge?.copyWith(color: cs.primary),
              ),
            ),
            ...category.sounds.map((sound) {
              final resolved = overrides[sound.id] ?? sound;
              final isThis = ap.currentSoundId == resolved.id;
              return SoundTile(
                sound: resolved,
                isPlaying: isThis && ap.isPlaying,
                onPlayTap: () => ref
                    .read(audioPlayerProvider.notifier)
                    .togglePlay(resolved),
                playPosition: isThis ? ap.position : null,
                playDuration: isThis ? ap.duration : null,
                onSeek: isThis
                    ? (d) => ref.read(audioPlayerProvider.notifier).seek(d)
                    : null,
                folderName: resolved.folderId == null
                    ? null
                    : folderNameById[resolved.folderId!],
                menuItems: const [
                  PopupMenuItem(
                    value: 'assign',
                    child: Text('Assign to event...'),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Trim / Edit'),
                  ),
                  PopupMenuItem(
                    value: 'labels',
                    child: Text('Manage labels'),
                  ),
                ],
                onMenuSelected: (v) async {
                  if (v == 'edit') {
                    final updated = await Navigator.of(context).push<SoundItem>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => AudioEditorScreen(sound: resolved),
                      ),
                    );
                    if (updated != null && context.mounted) {
                      await ref
                          .read(soundTrimStoreProvider.notifier)
                          .put(updated);
                    }
                  } else if (v == 'assign') {
                    await showAssignToEventDialog(context, ref, resolved);
                  } else if (v == 'labels') {
                    await onManageLabels(resolved);
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class _MyFilesTab extends ConsumerWidget {
  final String searchQuery;
  final Set<SoundSource> sourceFilter;
  final bool favoritesOnly;
  final Duration maxDuration;
  final String? selectedTagFilter;
  final String? selectedFolderFilterId;
  final Map<String, String> folderNameById;
  final Future<void> Function(SoundItem sound) onManageLabels;

  const _MyFilesTab({
    required this.searchQuery,
    required this.sourceFilter,
    required this.favoritesOnly,
    required this.maxDuration,
    required this.selectedTagFilter,
    required this.selectedFolderFilterId,
    required this.folderNameById,
    required this.onManageLabels,
  });

  List<SoundItem> _filter(List<SoundItem> items) {
    final q = searchQuery.toLowerCase();
    return items.where((s) {
      final matchesRecordedSource = s.source == SoundSource.recording;
      final matchesQuery =
          q.isEmpty || s.name.toLowerCase().contains(q);
      final matchesSource = sourceFilter.contains(s.source);
      final matchesDuration = s.effectiveDuration <= maxDuration;
      final matchesFav = !favoritesOnly || s.isFavorite;
      final matchesTag =
          selectedTagFilter == null || s.tags.contains(selectedTagFilter);
      final matchesFolder =
          selectedFolderFilterId == null || s.folderId == selectedFolderFilterId;
      return matchesRecordedSource &&
          matchesQuery &&
          matchesSource &&
          matchesDuration &&
          matchesFav &&
          matchesTag &&
          matchesFolder;
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final files = ref.watch(userFilesProvider);
    final overrides = ref.watch(soundTrimStoreProvider);
    final ap = ref.watch(audioPlayerProvider);
    final filtered = _filter(files);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.folderOpen, size: 48, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'No audio files added yet.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => pickAndAddUserFile(context, ref),
                child: const Text('Browse Files'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ImportUrlScreen(),
                  ),
                ),
                child: const Text('Import from URL'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final sound = filtered[index];
        final resolved = overrides[sound.id] ?? sound;
        final isThis = ap.currentSoundId == resolved.id;
        return SoundTile(
          sound: resolved,
          isPlaying: isThis && ap.isPlaying,
          onFavoriteToggle: () =>
              ref.read(userFilesProvider.notifier).toggleFavorite(sound.id),
          onPlayTap: () =>
              ref.read(audioPlayerProvider.notifier).togglePlay(resolved),
          playPosition: isThis ? ap.position : null,
          playDuration: isThis ? ap.duration : null,
          onSeek: isThis
              ? (d) => ref.read(audioPlayerProvider.notifier).seek(d)
              : null,
          folderName: resolved.folderId == null
              ? null
              : folderNameById[resolved.folderId!],
          menuItems: const [
            PopupMenuItem(value: 'assign', child: Text('Assign to event...')),
            PopupMenuItem(value: 'edit', child: Text('Trim / Edit')),
            PopupMenuItem(value: 'labels', child: Text('Manage labels')),
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onMenuSelected: (v) async {
            if (v == 'edit') {
              final updated = await Navigator.of(context).push<SoundItem>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AudioEditorScreen(sound: resolved),
                ),
              );
              if (updated != null && context.mounted) {
                await ref.read(soundTrimStoreProvider.notifier).put(updated);
              }
            } else if (v == 'assign') {
              await showAssignToEventDialog(context, ref, resolved);
            } else if (v == 'labels') {
              await onManageLabels(resolved);
            } else if (v == 'rename') {
              final ctrl = TextEditingController(text: resolved.name);
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rename'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, ctrl.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (name != null &&
                  name.isNotEmpty &&
                  context.mounted) {
                await ref
                    .read(userFilesProvider.notifier)
                    .rename(sound.id, name);
              }
            } else if (v == 'delete') {
              await ref.read(userFilesProvider.notifier).remove(sound.id);
            }
          },
        );
      },
    );
  }
}

class _RecordingsTab extends ConsumerWidget {
  final String searchQuery;
  final Set<SoundSource> sourceFilter;
  final bool favoritesOnly;
  final Duration maxDuration;
  final String? selectedTagFilter;
  final String? selectedFolderFilterId;
  final Map<String, String> folderNameById;
  final Future<void> Function(SoundItem sound) onManageLabels;

  const _RecordingsTab({
    required this.searchQuery,
    required this.sourceFilter,
    required this.favoritesOnly,
    required this.maxDuration,
    required this.selectedTagFilter,
    required this.selectedFolderFilterId,
    required this.folderNameById,
    required this.onManageLabels,
  });

  List<SoundItem> _filter(List<SoundItem> items) {
    final q = searchQuery.toLowerCase();
    return items.where((s) {
      final matchesQuery =
          q.isEmpty || s.name.toLowerCase().contains(q);
      final matchesSource = sourceFilter.contains(s.source);
      final matchesDuration = s.effectiveDuration <= maxDuration;
      final matchesFav = !favoritesOnly || s.isFavorite;
      final matchesTag =
          selectedTagFilter == null || s.tags.contains(selectedTagFilter);
      final matchesFolder =
          selectedFolderFilterId == null || s.folderId == selectedFolderFilterId;
      return matchesQuery &&
          matchesSource &&
          matchesDuration &&
          matchesFav &&
          matchesTag &&
          matchesFolder;
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recordings = ref.watch(recordingsProvider);
    final overrides = ref.watch(soundTrimStoreProvider);
    final ap = ref.watch(audioPlayerProvider);
    final filtered = _filter(recordings);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mic, size: 48, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'No recordings yet.\nRecord your first sound clip.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(selectedTabProvider.notifier).state = 2,
                child: const Text('Record Now'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final sound = filtered[index];
        final resolved = overrides[sound.id] ?? sound;
        final isThis = ap.currentSoundId == resolved.id;
        return SoundTile(
          sound: resolved,
          isPlaying: isThis && ap.isPlaying,
          onFavoriteToggle: () =>
              ref.read(recordingsProvider.notifier).toggleFavorite(sound.id),
          onPlayTap: () =>
              ref.read(audioPlayerProvider.notifier).togglePlay(resolved),
          playPosition: isThis ? ap.position : null,
          playDuration: isThis ? ap.duration : null,
          onSeek: isThis
              ? (d) => ref.read(audioPlayerProvider.notifier).seek(d)
              : null,
          folderName: resolved.folderId == null
              ? null
              : folderNameById[resolved.folderId!],
          menuItems: const [
            PopupMenuItem(value: 'assign', child: Text('Assign to event...')),
            PopupMenuItem(value: 'edit', child: Text('Trim / Edit')),
            PopupMenuItem(value: 'labels', child: Text('Manage labels')),
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onMenuSelected: (v) async {
            if (v == 'edit') {
              final updated = await Navigator.of(context).push<SoundItem>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AudioEditorScreen(sound: resolved),
                ),
              );
              if (updated != null && context.mounted) {
                await ref.read(soundTrimStoreProvider.notifier).put(updated);
              }
            } else if (v == 'assign') {
              await showAssignToEventDialog(context, ref, resolved);
            } else if (v == 'labels') {
              await onManageLabels(resolved);
            } else if (v == 'rename') {
              final ctrl = TextEditingController(text: resolved.name);
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rename'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, ctrl.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (name != null &&
                  name.isNotEmpty &&
                  context.mounted) {
                await ref
                    .read(recordingsProvider.notifier)
                    .rename(sound.id, name);
              }
            } else if (v == 'delete') {
              await ref.read(recordingsProvider.notifier).remove(sound.id);
            }
          },
        );
      },
    );
  }
}
