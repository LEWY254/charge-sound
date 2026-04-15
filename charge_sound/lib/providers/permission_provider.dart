import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../platform/android_write_settings.dart';

enum AppPermission {
  microphone,
  storage,
  systemSettings,
  notifications,
  sms,
}

final permissionProvider = AsyncNotifierProvider<PermissionNotifier,
    Map<AppPermission, PermissionStatus>>(PermissionNotifier.new);

class PermissionNotifier
    extends AsyncNotifier<Map<AppPermission, PermissionStatus>> {
  @override
  Future<Map<AppPermission, PermissionStatus>> build() async {
    return _loadStatuses();
  }

  Future<void> checkAll() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _loadStatuses());
  }

  Future<bool> isGranted(AppPermission permission) async {
    final map = state.value ?? await _loadStatuses();
    final status = map[permission];
    return status == PermissionStatus.granted;
  }

  Future<void> request(AppPermission permission) async {
    switch (permission) {
      case AppPermission.microphone:
        await Permission.microphone.request();
        break;
      case AppPermission.storage:
        await Permission.storage.request();
        break;
      case AppPermission.systemSettings:
        // WRITE_SETTINGS: user must toggle in system UI (plan).
        await openAppSettings();
        break;
      case AppPermission.notifications:
        await Permission.notification.request();
        break;
      case AppPermission.sms:
        await Permission.sms.request();
        break;
    }
    await checkAll();
  }

  Future<void> openSettingsFor(AppPermission permission) async {
    if (permission == AppPermission.systemSettings && Platform.isAndroid) {
      await AndroidWriteSettings.openWriteSettingsScreen();
    } else {
      await openAppSettings();
    }
    await checkAll();
  }

  Future<Map<AppPermission, PermissionStatus>> _loadStatuses() async {
    final mic = await Permission.microphone.status;
    final storage = await Permission.storage.status;
    final notif = await Permission.notification.status;
    final sms = await Permission.sms.status;

    final system = await _systemSettingsStatus();

    return {
      AppPermission.microphone: mic,
      AppPermission.storage: storage,
      AppPermission.systemSettings: system,
      AppPermission.notifications: notif,
      AppPermission.sms: sms,
    };
  }

  Future<PermissionStatus> _systemSettingsStatus() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    final ok = await AndroidWriteSettings.canWriteSettings();
    return ok ? PermissionStatus.granted : PermissionStatus.denied;
  }
}
