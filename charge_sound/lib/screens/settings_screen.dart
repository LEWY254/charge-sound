import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/service_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/royalty_free_terms_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).checkAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).checkAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final serviceOn = ref.watch(serviceEnabledProvider);
    final batteryThreshold = ref.watch(batteryThresholdProvider);
    final eventPlaybackMaxMs = ref.watch(eventPlaybackMaxMsProvider);
    final eventPlaybackSeconds = eventPlaybackMaxMs / 1000.0;
    final previewCapEnabled = ref.watch(previewDurationCapEnabledProvider);
    final themeMode = ref.watch(themeModeProvider);
    final permissionsAsync = ref.watch(permissionProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(label: 'MONITORING'),
          Card(
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Background Service',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  subtitle: Text(
                    'Detect charge, battery, and boot events even when app is closed.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: serviceOn,
                  onChanged: (_) =>
                      ref.read(serviceEnabledProvider.notifier).toggle(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Battery Low Threshold',
                            style: tt.titleSmall
                                ?.copyWith(color: cs.onSurface)),
                      ),
                      Text(
                        '${batteryThreshold.round()}%',
                        style:
                            tt.labelLarge?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: batteryThreshold,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  label: '${batteryThreshold.round()}%',
                  onChanged: (v) => ref
                      .read(batteryThresholdProvider.notifier)
                      .setThreshold(v),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Alert when battery drops below this.',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Event Sound Duration',
                          style:
                              tt.titleSmall?.copyWith(color: cs.onSurface),
                        ),
                      ),
                      Text(
                        '${eventPlaybackSeconds.toStringAsFixed(1)}s',
                        style: tt.labelLarge?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: eventPlaybackSeconds,
                  min: 0.5,
                  max: 5.0,
                  divisions: 18,
                  label: '${eventPlaybackSeconds.toStringAsFixed(1)}s',
                  onChanged: (v) => ref
                      .read(eventPlaybackMaxMsProvider.notifier)
                      .setMaxDurationMs((v * 1000).round()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Default cap for triggered event playback. '
                    'Lower values keep sounds short.',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    'Apply cap to in-app previews',
                    style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  ),
                  subtitle: Text(
                    'When enabled, manual preview playback uses the same duration cap.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: previewCapEnabled,
                  onChanged: (v) => ref
                      .read(previewDurationCapEnabledProvider.notifier)
                      .setEnabled(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(label: 'APPEARANCE'),
          Card(
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(LucideIcons.smartphone, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(LucideIcons.sun, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(LucideIcons.moon, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(s.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(label: 'ACCOUNT'),
          Card(
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user == null
                        ? 'Not connected'
                        : (user.isAnonymous
                            ? 'Anonymous backup profile'
                            : (user.email ?? 'Signed in')),
                    style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user == null
                        ? 'Sign in to sync across devices.'
                        : (user.isAnonymous
                            ? 'Upgrade to email or Google to keep access across devices.'
                            : 'Cloud sync is enabled for this account.'),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _openEmailAuthDialog(context),
                        child: Text(user != null && !user.isAnonymous
                            ? 'Email account'
                            : 'Sign in with Email'),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          try {
                            final response = await ref
                                .read(authServiceProvider)
                                .signInWithGoogle();
                            if (response == null) {
                              _showMessage(
                                'Google sign-in is unavailable right now. Please try again later.',
                              );
                              return;
                            }
                            _showMessage('Signed in with Google.');
                          } catch (e) {
                            _showMessage('Google sign-in failed: $e');
                          }
                        },
                        child: const Text('Sign in with Google'),
                      ),
                      if (user != null && !user.isAnonymous)
                        OutlinedButton(
                          onPressed: () async {
                            await ref.read(authServiceProvider).signOut();
                            _showMessage('Signed out.');
                          },
                          child: const Text('Sign out'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(label: 'PERMISSIONS'),
          Card(
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: permissionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load permissions: $e'),
              ),
              data: (map) => Column(
                children: [
                  _PermissionTile(
                    title: 'Microphone',
                    icon: LucideIcons.mic,
                    status: map[AppPermission.microphone],
                    isLoading: false,
                    appPermission: AppPermission.microphone,
                  ),
                  _PermissionTile(
                    title: 'Storage / Media',
                    icon: LucideIcons.hardDrive,
                    status: map[AppPermission.storage],
                    isLoading: false,
                    appPermission: AppPermission.storage,
                  ),
                  _PermissionTile(
                    title: 'Modify System Settings',
                    subtitle:
                        'Required for changing ringtone, notification, and alarm sounds.',
                    icon: LucideIcons.settings,
                    status: map[AppPermission.systemSettings],
                    isLoading: false,
                    appPermission: AppPermission.systemSettings,
                  ),
                  _PermissionTile(
                    title: 'Notifications',
                    icon: LucideIcons.bell,
                    status: map[AppPermission.notifications],
                    isLoading: false,
                    appPermission: AppPermission.notifications,
                  ),
                  _PermissionTile(
                    title: 'SMS',
                    icon: LucideIcons.messageCircle,
                    status: map[AppPermission.sms],
                    isLoading: false,
                    appPermission: AppPermission.sms,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(label: 'ABOUT'),
          Card(
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  title: Text('Version',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  trailing: Text('1.0.0',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: Text('Rate this app',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  trailing:
                      Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.soundtrigger.app',
                    );
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: Text('Open source licenses',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  trailing:
                      Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
                  onTap: () => showLicensePage(context: context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: Text('Royalty-free terms',
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                  trailing:
                      Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
                  onTap: () => showRoyaltyFreeTermsSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openEmailAuthDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Email account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop('signup'),
              child: const Text('Create'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('signin'),
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
    if (mode == null || !context.mounted) return;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.length < 6) {
      _showMessage('Enter a valid email and password.');
      return;
    }
    try {
      final auth = ref.read(authServiceProvider);
      if (mode == 'signup') {
        final response = await auth
            .signUpWithEmail(email: email, password: password);
        if (response == null) {
          _showMessage(
            'Email sign-up is unavailable right now. Please try again later.',
          );
          return;
        }
        _showMessage(
          'Account created. Check your email to verify before signing in.',
        );
      } else {
        final response = await auth
            .signInWithEmail(email: email, password: password);
        if (response == null) {
          _showMessage(
            'Email sign-in is unavailable right now. Please try again later.',
          );
          return;
        }
        _showMessage('Signed in.');
      }
    } catch (e) {
      _showMessage('Email auth failed: $e');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label,
        style: tt.labelLarge?.copyWith(color: cs.primary),
      ),
    );
  }
}

class _PermissionTile extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final PermissionStatus? status;
  final bool isLoading;
  final AppPermission appPermission;
  final bool isLast;

  const _PermissionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.status,
    required this.isLoading,
    required this.appPermission,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(permissionProvider.notifier);

    final (chipLabel, bg, fg) = _chipStyle(cs);

    void onTileTap() {
      if (isLoading || status == null) return;
      if (status == PermissionStatus.permanentlyDenied) {
        notifier.openSettingsFor(appPermission);
      } else {
        notifier.request(appPermission);
      }
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          title: Text(title,
              style: tt.titleSmall?.copyWith(color: cs.onSurface)),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(
                  chipLabel,
                  style: tt.labelSmall?.copyWith(color: fg),
                ),
                backgroundColor: bg,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: cs.onSurfaceVariant),
            ],
          ),
          onTap: onTileTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }

  (String, Color, Color) _chipStyle(ColorScheme cs) {
    if (isLoading || status == null) {
      return (
        'Checking...',
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
      );
    }
    if (status == PermissionStatus.granted) {
      return ('Granted', cs.primaryContainer, cs.onPrimaryContainer);
    }
    if (status == PermissionStatus.permanentlyDenied) {
      return ('Open Settings', cs.errorContainer, cs.onErrorContainer);
    }
    return ('Denied', cs.errorContainer, cs.onErrorContainer);
  }
}
