import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/charge_sound_service.dart';
import 'sync_provider.dart';
import 'theme_provider.dart';

const _serviceEnabledKey = 'service_enabled';
const _batteryThresholdKey = 'battery_threshold';
const _eventPlaybackMaxMsKey = 'event_playback_max_ms';
const _previewDurationCapEnabledKey = 'preview_duration_cap_enabled';

final serviceEnabledProvider =
    NotifierProvider<ServiceEnabledNotifier, bool>(ServiceEnabledNotifier.new);

class ServiceEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSaved();
    return true;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final localValue = prefs.getBool(_serviceEnabledKey);
    if (localValue != null) state = localValue;

    final remote = await ref.read(syncServiceProvider).pullDeviceSettings();
    if (remote != null) {
      state = remote.serviceEnabled;
      await prefs.setBool(_serviceEnabledKey, state);
      await ref
          .read(batteryThresholdProvider.notifier)
          ._applyRemote(remote.batteryThreshold);
      final parsedMode = ThemeMode.values.firstWhere(
        (m) => m.name == remote.themeMode,
        orElse: () => ThemeMode.system,
      );
      await ref.read(themeModeProvider.notifier).setThemeMode(parsedMode);
    }

    if (!kIsWeb && state) {
      await ChargeSoundServiceChannel.start();
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serviceEnabledKey, state);
    if (!kIsWeb) {
      if (state) {
        await ChargeSoundServiceChannel.start();
      } else {
        await ChargeSoundServiceChannel.stop();
      }
    }
    await _syncDeviceSettings();
  }

  Future<void> _syncDeviceSettings() async {
    final threshold = ref.read(batteryThresholdProvider);
    final themeMode = ref.read(themeModeProvider).name;
    await ref.read(syncServiceProvider).pushDeviceSettings(
          serviceEnabled: state,
          batteryThreshold: threshold,
          themeMode: themeMode,
        );
  }
}

final batteryThresholdProvider =
    NotifierProvider<BatteryThresholdNotifier, double>(
        BatteryThresholdNotifier.new);

class BatteryThresholdNotifier extends Notifier<double> {
  @override
  double build() {
    _loadSaved();
    return 15.0;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_batteryThresholdKey);
    if (value != null) state = value;
  }

  Future<void> _applyRemote(double value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_batteryThresholdKey, value);
  }

  Future<void> setThreshold(double value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_batteryThresholdKey, value);
    final serviceEnabled = ref.read(serviceEnabledProvider);
    final themeMode = ref.read(themeModeProvider).name;
    await ref.read(syncServiceProvider).pushDeviceSettings(
          serviceEnabled: serviceEnabled,
          batteryThreshold: state,
          themeMode: themeMode,
        );
  }
}

final eventPlaybackMaxMsProvider =
    NotifierProvider<EventPlaybackMaxMsNotifier, int>(
        EventPlaybackMaxMsNotifier.new);

class EventPlaybackMaxMsNotifier extends Notifier<int> {
  @override
  int build() {
    _loadSaved();
    return 2000; // default: short preview/event clip
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_eventPlaybackMaxMsKey);
    if (value != null && value > 0) state = value;
  }

  Future<void> setMaxDurationMs(int value) async {
    if (value <= 0) return;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_eventPlaybackMaxMsKey, value);
  }
}

final previewDurationCapEnabledProvider =
    NotifierProvider<PreviewDurationCapEnabledNotifier, bool>(
        PreviewDurationCapEnabledNotifier.new);

class PreviewDurationCapEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSaved();
    return false;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_previewDurationCapEnabledKey);
    if (value != null) state = value;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_previewDurationCapEnabledKey, enabled);
  }
}
