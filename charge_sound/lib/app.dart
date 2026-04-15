import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';

class SoundTriggerApp extends ConsumerWidget {
  const SoundTriggerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authBootstrapProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboardingDone = ref.watch(onboardingCompletedProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Sound Trigger',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(lightDynamic),
          darkTheme: buildDarkTheme(darkDynamic),
          themeMode: themeMode,
          navigatorObservers: [_StopAudioOnNavigationObserver(ref)],
          home: onboardingDone ? const AppShell() : const OnboardingScreen(),
        );
      },
    );
  }
}

class _StopAudioOnNavigationObserver extends NavigatorObserver {
  _StopAudioOnNavigationObserver(this.ref);

  final WidgetRef ref;

  void _stopPreview() {
    ref.read(audioPlayerProvider.notifier).stop();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stopPreview();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stopPreview();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _stopPreview();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
