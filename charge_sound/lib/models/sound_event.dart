import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Event types ───────────────────────────────────────────────────────────────

enum SoundEventType {
  // Power & Battery
  chargerIn,
  chargerOut,
  batteryFull,
  batteryLow,
  batterySaverOn,
  batterySaverOff,
  // Screen & Device
  bootSound,
  screenOn,
  screenOff,
  deviceUnlocked,
  // Audio & Connectivity
  headphonesIn,
  headphonesOut,
  bluetoothConnected,
  bluetoothDisconnected,
  airplaneModeOn,
  airplaneModeOff,
  nfcScanned,
  // System Sounds
  ringtone,
  notification,
  alarm,
  smsTone,
  // Motion & Gestures
  phoneShaken,
  phoneFaceDown,
}

extension SoundEventTypeX on SoundEventType {
  String get label => switch (this) {
    SoundEventType.chargerIn => 'Charger In',
    SoundEventType.chargerOut => 'Charger Out',
    SoundEventType.batteryFull => 'Battery Full',
    SoundEventType.batteryLow => 'Battery Low',
    SoundEventType.batterySaverOn => 'Battery Saver On',
    SoundEventType.batterySaverOff => 'Battery Saver Off',
    SoundEventType.bootSound => 'Boot Sound',
    SoundEventType.screenOn => 'Screen On',
    SoundEventType.screenOff => 'Screen Off',
    SoundEventType.deviceUnlocked => 'Device Unlocked',
    SoundEventType.headphonesIn => 'Headphones In',
    SoundEventType.headphonesOut => 'Headphones Out',
    SoundEventType.bluetoothConnected => 'Bluetooth Connected',
    SoundEventType.bluetoothDisconnected => 'Bluetooth Disconnected',
    SoundEventType.airplaneModeOn => 'Airplane Mode On',
    SoundEventType.airplaneModeOff => 'Airplane Mode Off',
    SoundEventType.nfcScanned => 'NFC Scanned',
    SoundEventType.ringtone => 'Ringtone',
    SoundEventType.notification => 'Notification',
    SoundEventType.alarm => 'Alarm',
    SoundEventType.smsTone => 'SMS Tone',
    SoundEventType.phoneShaken => 'Phone Shaken',
    SoundEventType.phoneFaceDown => 'Phone Face Down',
  };

  String get description => switch (this) {
    SoundEventType.chargerIn => 'Plays when you plug in.',
    SoundEventType.chargerOut => 'Plays when you unplug.',
    SoundEventType.batteryFull => 'Plays when battery reaches 100%.',
    SoundEventType.batteryLow => 'Plays when battery drops below threshold.',
    SoundEventType.batterySaverOn => 'Plays when battery saver is enabled.',
    SoundEventType.batterySaverOff => 'Plays when battery saver is disabled.',
    SoundEventType.bootSound => 'Plays on device startup.',
    SoundEventType.screenOn => 'Plays when the screen turns on.',
    SoundEventType.screenOff => 'Plays when the screen turns off.',
    SoundEventType.deviceUnlocked => 'Plays when you unlock the device.',
    SoundEventType.headphonesIn => 'Plays when headphones are plugged in.',
    SoundEventType.headphonesOut => 'Plays when headphones are unplugged.',
    SoundEventType.bluetoothConnected => 'Plays when a Bluetooth device connects.',
    SoundEventType.bluetoothDisconnected => 'Plays when a Bluetooth device disconnects.',
    SoundEventType.airplaneModeOn => 'Plays when airplane mode turns on.',
    SoundEventType.airplaneModeOff => 'Plays when airplane mode turns off.',
    SoundEventType.nfcScanned => 'Plays when an NFC tag is scanned.',
    SoundEventType.ringtone => 'Set as your phone ringtone.',
    SoundEventType.notification => 'Set as notification sound.',
    SoundEventType.alarm => 'Set as alarm tone.',
    SoundEventType.smsTone => 'Plays for incoming messages.',
    SoundEventType.phoneShaken => 'Plays when you shake the phone.',
    SoundEventType.phoneFaceDown => 'Plays when the phone is placed face down.',
  };

  IconData get icon => switch (this) {
    SoundEventType.chargerIn => LucideIcons.zap,
    SoundEventType.chargerOut => LucideIcons.zapOff,
    SoundEventType.batteryFull => LucideIcons.batteryFull,
    SoundEventType.batteryLow => LucideIcons.batteryLow,
    SoundEventType.batterySaverOn => LucideIcons.leaf,
    SoundEventType.batterySaverOff => LucideIcons.batteryCharging,
    SoundEventType.bootSound => LucideIcons.power,
    SoundEventType.screenOn => LucideIcons.monitor,
    SoundEventType.screenOff => LucideIcons.monitorOff,
    SoundEventType.deviceUnlocked => LucideIcons.unlock,
    SoundEventType.headphonesIn => LucideIcons.headphones,
    SoundEventType.headphonesOut => LucideIcons.earOff,
    SoundEventType.bluetoothConnected => LucideIcons.bluetoothConnected,
    SoundEventType.bluetoothDisconnected => LucideIcons.bluetoothOff,
    SoundEventType.airplaneModeOn => LucideIcons.plane,
    SoundEventType.airplaneModeOff => LucideIcons.globe,
    SoundEventType.nfcScanned => LucideIcons.nfc,
    SoundEventType.ringtone => LucideIcons.phone,
    SoundEventType.notification => LucideIcons.bell,
    SoundEventType.alarm => LucideIcons.alarmClock,
    SoundEventType.smsTone => LucideIcons.messageCircle,
    SoundEventType.phoneShaken => LucideIcons.vibrate,
    SoundEventType.phoneFaceDown => LucideIcons.smartphone,
  };

  SoundEventCategory get category => switch (this) {
    SoundEventType.chargerIn ||
    SoundEventType.chargerOut ||
    SoundEventType.batteryFull ||
    SoundEventType.batteryLow ||
    SoundEventType.batterySaverOn ||
    SoundEventType.batterySaverOff =>
      SoundEventCategory.powerAndBattery,
    SoundEventType.bootSound ||
    SoundEventType.screenOn ||
    SoundEventType.screenOff ||
    SoundEventType.deviceUnlocked =>
      SoundEventCategory.screenAndDevice,
    SoundEventType.headphonesIn ||
    SoundEventType.headphonesOut ||
    SoundEventType.bluetoothConnected ||
    SoundEventType.bluetoothDisconnected ||
    SoundEventType.airplaneModeOn ||
    SoundEventType.airplaneModeOff ||
    SoundEventType.nfcScanned =>
      SoundEventCategory.audioAndConnectivity,
    SoundEventType.ringtone ||
    SoundEventType.notification ||
    SoundEventType.alarm ||
    SoundEventType.smsTone =>
      SoundEventCategory.systemSounds,
    SoundEventType.phoneShaken ||
    SoundEventType.phoneFaceDown =>
      SoundEventCategory.motionAndGestures,
  };

  bool get isSystemDefault =>
      this == SoundEventType.ringtone ||
      this == SoundEventType.notification ||
      this == SoundEventType.alarm;
}

// ── Categories ────────────────────────────────────────────────────────────────

enum SoundEventCategory {
  powerAndBattery,
  screenAndDevice,
  audioAndConnectivity,
  systemSounds,
  motionAndGestures,
}

extension SoundEventCategoryX on SoundEventCategory {
  String get label => switch (this) {
    SoundEventCategory.powerAndBattery => 'Power & Battery',
    SoundEventCategory.screenAndDevice => 'Screen & Device',
    SoundEventCategory.audioAndConnectivity => 'Audio & Connectivity',
    SoundEventCategory.systemSounds => 'System Sounds',
    SoundEventCategory.motionAndGestures => 'Motion & Gestures',
  };

  IconData get icon => switch (this) {
    SoundEventCategory.powerAndBattery => LucideIcons.batteryCharging,
    SoundEventCategory.screenAndDevice => LucideIcons.smartphone,
    SoundEventCategory.audioAndConnectivity => LucideIcons.bluetooth,
    SoundEventCategory.systemSounds => LucideIcons.volume2,
    SoundEventCategory.motionAndGestures => LucideIcons.vibrate,
  };

  List<SoundEventType> get events => SoundEventType.values
      .where((e) => e.category == this)
      .toList();
}
