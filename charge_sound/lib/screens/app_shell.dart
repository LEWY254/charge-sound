import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../models/sound_item.dart';
import '../platform/share_intent.dart';
import '../providers/audio_player_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_files_provider.dart';
import '../utils/app_audio_dirs.dart';
import '../utils/audio_duration_probe.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'sound_library_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  List<Widget> _screens() => [
        const HomeScreen(),
        const SoundLibraryScreen(),
        const RecordScreen(),
        const SettingsScreen(),
      ];

  List<NavigationDestination> _destinations() => [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(LucideIcons.music),
          selectedIcon: Icon(LucideIcons.music),
          label: 'Sounds',
        ),
        const NavigationDestination(
          icon: Icon(LucideIcons.mic),
          selectedIcon: Icon(LucideIcons.mic),
          label: 'Record',
        ),
        const NavigationDestination(
          icon: Icon(LucideIcons.slidersHorizontal),
          selectedIcon: Icon(LucideIcons.slidersHorizontal),
          label: 'Settings',
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleShareIntent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop any in-app preview when user leaves the app or focus.
    if (state != AppLifecycleState.resumed) {
      ref.read(audioPlayerProvider.notifier).stop();
    }
  }

  Future<void> _handleShareIntent() async {
    final path = await ShareIntentChannel.getInitialSharedAudioPath();
    if (path == null || path.isEmpty || !mounted) return;

    try {
      final dir = await ensureUserFilesDirectory();
      final ext = p.extension(path).isEmpty ? '.mp3' : p.extension(path);
      final destPath =
          '${dir.path}/shared_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(path).copy(destPath);
      final duration = await probeAudioFileDuration(destPath);
      final item = SoundItem(
        id: 'shared_${DateTime.now().millisecondsSinceEpoch}',
        name: p.basenameWithoutExtension(destPath),
        path: destPath,
        duration: duration,
        source: SoundSource.file,
        createdAt: DateTime.now(),
      );
      await ref.read(userFilesProvider.notifier).add(item);
      if (!mounted) return;
      ref.read(selectedTabProvider.notifier).state = 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.name}" added to your sounds.')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens();
    final destinations = _destinations();
    final selected = ref.watch(selectedTabProvider);
    final index = selected.clamp(0, screens.length - 1);
    if (index != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedTabProvider.notifier).state = index;
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i != index) {
            // Stop preview playback when user switches tabs.
            ref.read(audioPlayerProvider.notifier).stop();
          }
          ref.read(selectedTabProvider.notifier).state = i;
        },
        destinations: destinations,
      ),
    );
  }
}
