import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_provider.dart';
import 'theme_provider.dart';

const _serviceEnabledKey = 'service_enabled';
const _batteryThresholdKey = 'battery_threshold';

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
    final value = prefs.getBool(_serviceEnabledKey);
    if (value != null) state = value;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serviceEnabledKey, state);
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
