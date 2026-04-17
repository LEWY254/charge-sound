import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/onboarding_provider.dart';
import '../providers/permission_provider.dart';
import 'app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _complete() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingPage(
        title: 'Welcome to Sound Trigger',
        subtitle: 'Customize sounds for charging, notifications, alarms, and more.',
      ),
      const _PermissionsPage(),
      _OnboardingPage(
        title: 'Browse Cloud Sounds',
        subtitle: 'Find sounds in Market and add only what you want.',
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

/// A dedicated permissions page shown during onboarding.
/// On first appearance it silently requests all non-system permissions that
/// are not yet granted. The user can also tap individual rows to re-request
/// any that are still denied.
class _PermissionsPage extends ConsumerStatefulWidget {
  const _PermissionsPage();

  @override
  ConsumerState<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<_PermissionsPage> {
  bool _autoRequested = false;

  static const _permissionMeta = [
    (
      permission: AppPermission.microphone,
      label: 'Microphone',
      description: 'Record your own custom sounds.',
      icon: LucideIcons.mic,
      required: true,
    ),
    (
      permission: AppPermission.storage,
      label: 'Storage / Media',
      description: 'Import audio files from your device.',
      icon: LucideIcons.hardDrive,
      required: true,
    ),
    (
      permission: AppPermission.notifications,
      label: 'Notifications',
      description: 'Show the background service notification.',
      icon: LucideIcons.bell,
      required: true,
    ),
    (
      permission: AppPermission.sms,
      label: 'SMS',
      description: 'Play a custom sound for incoming messages.',
      icon: LucideIcons.messageCircle,
      required: false,
    ),
    (
      permission: AppPermission.systemSettings,
      label: 'Modify System Settings',
      description: 'Set a custom ringtone, notification, or alarm sound.',
      icon: LucideIcons.settings,
      required: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoRequest());
  }

  Future<void> _autoRequest() async {
    if (_autoRequested) return;
    _autoRequested = true;
    // Request all non-system permissions if not already granted.
    await ref.read(permissionProvider.notifier).requestAllUngranted();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final permAsync = ref.watch(permissionProvider);
    final statuses = permAsync.value ?? {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permissions', style: tt.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Sound Trigger needs a few permissions to work properly. '
            'Required ones are requested automatically.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                for (final meta in _permissionMeta)
                  _PermissionRow(
                    label: meta.label,
                    description: meta.description,
                    icon: meta.icon,
                    isRequired: meta.required,
                    status: statuses[meta.permission],
                    onRequest: () => ref
                        .read(permissionProvider.notifier)
                        .request(meta.permission),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.isRequired,
    required this.status,
    required this.onRequest,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isRequired;
  final PermissionStatus? status;
  final VoidCallback onRequest;

  bool get _isGranted => status == PermissionStatus.granted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isGranted ? null : onRequest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isGranted
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isGranted ? LucideIcons.check : icon,
                    size: 20,
                    color: _isGranted
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label,
                              style: tt.titleSmall
                                  ?.copyWith(color: cs.onSurface)),
                          if (isRequired) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onPrimaryContainer),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isGranted)
                  Icon(LucideIcons.checkCircle,
                      size: 18, color: cs.primary)
                else
                  Icon(LucideIcons.chevronRight,
                      size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
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
