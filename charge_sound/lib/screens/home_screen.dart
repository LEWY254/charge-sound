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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final configs = ref.watch(eventConfigProvider);
    final serviceOn = ref.watch(serviceEnabledProvider);
    final eventSearch = ref.watch(homeEventSearchProvider).toLowerCase();

    final events = SoundEventType.values.where((e) {
      if (eventSearch.isEmpty) return true;
      final assigned = configs[e];
      return e.label.toLowerCase().contains(eventSearch) ||
          (assigned?.name.toLowerCase().contains(eventSearch) ?? false);
    }).toList();
    final pairedEvents = events.take(8).toList();
    final lastEvent = events.length > 8 ? events.last : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
          if (!serviceOn)
            SliverToBoxAdapter(
              child: MaterialBanner(
                content: Text(
                  'Monitoring paused. Events will not trigger sounds.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                leading: Icon(LucideIcons.pauseCircle, color: cs.onSurfaceVariant),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Customize every beep.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final eventType = pairedEvents[index];
                  final sound = configs[eventType];
                  return EventCard(
                    eventType: eventType,
                    assignedSound: sound,
                    onTap: () => _showEventDetail(context, eventType),
                    onPlayTap: sound == null
                        ? null
                        : () => ref
                            .read(audioPlayerProvider.notifier)
                            .togglePlay(sound),
                  );
                },
                childCount: pairedEvents.length,
              ),
            ),
          ),
          if (lastEvent != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 132,
                  child: Builder(
                    builder: (context) {
                      final e = lastEvent;
                      final lastSound = configs[e];
                      return EventCard(
                        eventType: e,
                        assignedSound: lastSound,
                        onTap: () => _showEventDetail(context, e),
                        onPlayTap: lastSound == null
                            ? null
                            : () => ref
                                .read(audioPlayerProvider.notifier)
                                .togglePlay(lastSound),
                      );
                    },
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
