import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/sound_event.dart';
import '../providers/audio_player_provider.dart';
import '../providers/event_config_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/event_card.dart';
import 'event_detail_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Categories collapsed by default: none. User can collapse any.
  final Set<SoundEventCategory> _collapsed = {};

  void _toggleCategory(SoundEventCategory cat) {
    setState(() {
      if (_collapsed.contains(cat)) {
        _collapsed.remove(cat);
      } else {
        _collapsed.add(cat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final configs = ref.watch(eventConfigProvider);
    final serviceOn = ref.watch(serviceEnabledProvider);
    final eventSearch = ref.watch(homeEventSearchProvider).toLowerCase();
    final searching = eventSearch.isNotEmpty;

    // Build filtered map: category → matching events
    final filtered = <SoundEventCategory, List<SoundEventType>>{};
    for (final cat in SoundEventCategory.values) {
      final matches = cat.events.where((e) {
        if (!searching) return true;
        final assigned = configs[e];
        return e.label.toLowerCase().contains(eventSearch) ||
            (assigned?.name.toLowerCase().contains(eventSearch) ?? false);
      }).toList();
      if (matches.isNotEmpty) filtered[cat] = matches;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                'Sound Trigger',
                style: tt.titleLarge?.copyWith(color: cs.onSurface),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: 'Search events',
                onPressed: () async {
                  final controller = TextEditingController(
                    text: ref.read(homeEventSearchProvider),
                  );
                  final query = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Search events'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Event or sound name',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, ''),
                          child: const Text('Clear'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(ctx, controller.text.trim()),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  );
                  if (query != null) {
                    ref.read(homeEventSearchProvider.notifier).state = query;
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      serviceOn ? 'ON' : 'OFF',
                      style: tt.labelSmall?.copyWith(
                        color: serviceOn ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: serviceOn,
                      onChanged: (_) =>
                          ref.read(serviceEnabledProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Paused banner ─────────────────────────────────────────────────
          if (!serviceOn)
            SliverToBoxAdapter(
              child: MaterialBanner(
                content: Text(
                  'Monitoring paused. Events will not trigger sounds.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                leading: Icon(LucideIcons.pauseCircle,
                    color: cs.onSurfaceVariant),
                backgroundColor: cs.surfaceContainerHighest,
                actions: [
                  TextButton(
                    onPressed: () =>
                        ref.read(serviceEnabledProvider.notifier).toggle(),
                    child: const Text('Resume'),
                  ),
                ],
              ),
            ),

          // ── Search active badge ───────────────────────────────────────────
          if (searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 14,
                        color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '"$eventSearch"',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => ref
                          .read(homeEventSearchProvider.notifier)
                          .state = '',
                      child: Icon(LucideIcons.x,
                          size: 14, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

          // ── Category sections ─────────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.searchX,
                        size: 48, color: cs.outlineVariant),
                    const SizedBox(height: 12),
                    Text('No events match "$eventSearch"',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            for (final entry in filtered.entries) ...[
              _CategoryHeader(
                category: entry.key,
                isCollapsed: _collapsed.contains(entry.key),
                assignedCount: entry.value
                    .where((e) => configs[e] != null)
                    .length,
                totalCount: entry.value.length,
                onToggle: () => _toggleCategory(entry.key),
              ),
              if (!_collapsed.contains(entry.key))
                _CategoryGrid(
                  events: entry.value,
                  configs: configs,
                  onTap: (e) => _showEventDetail(context, e),
                  onPlay: (sound) => ref
                      .read(audioPlayerProvider.notifier)
                      .togglePlay(sound),
                ),
            ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showEventDetail(BuildContext context, SoundEventType eventType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => EventDetailSheet(eventType: eventType),
    );
  }
}

// ── Category header sliver ────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.isCollapsed,
    required this.assignedCount,
    required this.totalCount,
    required this.onToggle,
  });

  final SoundEventCategory category;
  final bool isCollapsed;
  final int assignedCount;
  final int totalCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 8),
          child: Row(
            children: [
              Icon(category.icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: tt.labelLarge?.copyWith(color: cs.primary),
                ),
              ),
              if (assignedCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$assignedCount/$totalCount',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
              AnimatedRotation(
                turns: isCollapsed ? 0 : 0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronRight,
                    size: 16, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category grid sliver ──────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.events,
    required this.configs,
    required this.onTap,
    required this.onPlay,
  });

  final List<SoundEventType> events;
  final Map<SoundEventType, dynamic> configs;
  final void Function(SoundEventType) onTap;
  final void Function(dynamic) onPlay;

  @override
  Widget build(BuildContext context) {
    // Wrap items into rows of 2
    final rows = <List<SoundEventType>>[];
    for (var i = 0; i < events.length; i += 2) {
      rows.add(events.sublist(i, i + 2 > events.length ? events.length : i + 2));
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    for (var j = 0; j < row.length; j++) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: EventCard(
                            eventType: row[j],
                            assignedSound: configs[row[j]],
                            onTap: () => onTap(row[j]),
                            onPlayTap: configs[row[j]] == null
                                ? null
                                : () => onPlay(configs[row[j]]),
                          ),
                        ),
                      ),
                    ],
                    // Pad with an invisible spacer if odd last item
                    if (row.length == 1) ...[
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
