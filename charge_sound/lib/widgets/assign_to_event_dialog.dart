import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sound_event.dart';
import '../models/sound_item.dart';
import '../platform/android_write_settings.dart';
import '../providers/event_config_provider.dart';
import '../providers/permission_provider.dart';

Future<void> showAssignToEventDialog(
  BuildContext context,
  WidgetRef ref,
  SoundItem sound,
) async {
  final selected = <SoundEventType>{};
  final chosen = await showDialog<Set<SoundEventType>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Assign "${sound.name}" to events'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final e in SoundEventType.values)
                CheckboxListTile(
                  value: selected.contains(e),
                  title: Text(e.label),
                  subtitle: e.isSystemDefault
                      ? const Text('Sets system default')
                      : null,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selected.add(e);
                      } else {
                        selected.remove(e);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.pop(ctx, selected),
            child: const Text('Assign'),
          ),
        ],
      ),
    ),
  );
  if (chosen == null || chosen.isEmpty || !context.mounted) return;

  for (final event in chosen) {
    await ref.read(eventConfigProvider.notifier).assignSound(event, sound);
  }

  // For ringtone / notification / alarm, also apply as system default
  // if WRITE_SETTINGS permission is already granted (no-op otherwise).
  final systemEvents = chosen.where((e) => e.isSystemDefault).toList();
  if (systemEvents.isNotEmpty && context.mounted) {
    final hasPermission = await ref
        .read(permissionProvider.notifier)
        .isGranted(AppPermission.systemSettings);
    if (hasPermission && context.mounted) {
      for (final event in systemEvents) {
        await AndroidWriteSettings.setSystemDefaultSound(
          eventType: event.name,
          soundPath: sound.path,
          soundName: sound.name,
        );
      }
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Assigned to ${chosen.length} event(s)')),
  );
}
