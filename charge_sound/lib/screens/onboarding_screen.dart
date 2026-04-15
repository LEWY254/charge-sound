import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sound_item.dart';
import '../providers/onboarding_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/recordings_provider.dart';
import '../services/supabase_service.dart';
import 'app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _isSeedingPresets = false;
  bool _presetSeeded = false;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _complete() async {
    await _seedPresetPack(showFeedback: false);
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  String _presetIdForPath(String path) {
    final safe = path.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'preset_$safe';
  }

  Future<int> _seedPresetPack({bool showFeedback = true}) async {
    if (_isSeedingPresets) return 0;
    setState(() => _isSeedingPresets = true);
    final client = SupabaseService.client;
    if (client == null) {
      if (showFeedback) {
        _showMessage(
          'Preset pack is unavailable until cloud config is set up.',
        );
      }
      setState(() => _isSeedingPresets = false);
      return 0;
    }

    var added = 0;
    try {
      final rows = await client.from('preset_sounds').select('name,storage_path');
      final existing = ref.read(recordingsProvider);
      final existingIds = {
        for (final item in existing.where((e) => e.source == SoundSource.preset))
          item.id,
      };

      for (final row in rows.take(5)) {
        final path = row['storage_path'] as String;
        final presetId = _presetIdForPath(path);
        if (existingIds.contains(presetId)) continue;
        final signed = await client.storage
            .from('preset-packs')
            .createSignedUrl(path, 60 * 60);
        await ref.read(recordingsProvider.notifier).add(
              SoundItem(
                id: presetId,
                name: row['name'] as String,
                path: signed,
                duration: const Duration(seconds: 2),
                source: SoundSource.preset,
                createdAt: DateTime.now(),
              ),
            );
        existingIds.add(presetId);
        added++;
      }
      _presetSeeded = true;
      if (showFeedback) {
        if (added > 0) {
          _showMessage('Added $added preset sound${added == 1 ? '' : 's'}.');
        } else {
          _showMessage('Preset pack is already loaded.');
        }
      }
      return added;
    } catch (e) {
      if (showFeedback) {
        _showMessage('Failed to load presets: $e');
      }
      return 0;
    } finally {
      if (mounted) {
        setState(() => _isSeedingPresets = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingPage(
        title: 'Welcome to Sound Trigger',
        subtitle: 'Customize sounds for charging, notifications, alarms, and more.',
      ),
      _OnboardingPage(
        title: 'Permissions',
        subtitle: 'Grant microphone and storage access for recording and imports.',
        action: FilledButton.tonal(
          onPressed: () async {
            await ref.read(permissionProvider.notifier).request(AppPermission.microphone);
            await ref.read(permissionProvider.notifier).request(AppPermission.storage);
          },
          child: const Text('Grant now'),
        ),
      ),
      _OnboardingPage(
        title: 'Demo Preset Pack',
        subtitle: 'We can preload starter sounds from cloud presets.',
        action: FilledButton.tonal(
          onPressed: _isSeedingPresets
              ? null
              : () => _seedPresetPack(showFeedback: true),
          child: Text(
            _isSeedingPresets
                ? 'Loading...'
                : (_presetSeeded ? 'Reload Presets' : 'Load Presets'),
          ),
        ),
      ),
      _OnboardingPage(
        title: 'Ready to go',
        subtitle: 'Start recording and assigning your own sounds.',
        action: FilledButton(
          onPressed: _complete,
          child: const Text('Finish'),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_index < pages.length - 1)
                    FilledButton(
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Next'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: tt.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
