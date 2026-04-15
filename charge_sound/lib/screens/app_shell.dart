import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'sound_library_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _screens = [
    HomeScreen(),
    SoundLibraryScreen(),
    RecordScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.zap),
            selectedIcon: Icon(LucideIcons.zap),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.music),
            selectedIcon: Icon(LucideIcons.music),
            label: 'Sounds',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.mic),
            selectedIcon: Icon(LucideIcons.mic),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.slidersHorizontal),
            selectedIcon: Icon(LucideIcons.slidersHorizontal),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
