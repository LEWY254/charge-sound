import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum SoundEventType {
  chargerIn,
  chargerOut,
  batteryFull,
  batteryLow,
  ringtone,
  notification,
  alarm,
  bootSound,
  smsTone,
}

extension SoundEventTypeX on SoundEventType {
  String get label => switch (this) {
    SoundEventType.chargerIn => 'Charger In',
    SoundEventType.chargerOut => 'Charger Out',
    SoundEventType.batteryFull => 'Battery Full',
    SoundEventType.batteryLow => 'Battery Low',
    SoundEventType.ringtone => 'Ringtone',
    SoundEventType.notification => 'Notification',
    SoundEventType.alarm => 'Alarm',
    SoundEventType.bootSound => 'Boot Sound',
    SoundEventType.smsTone => 'SMS Tone',
  };

  String get description => switch (this) {
    SoundEventType.chargerIn => 'Plays when you plug in.',
    SoundEventType.chargerOut => 'Plays when you unplug.',
    SoundEventType.batteryFull => 'Plays when battery reaches 100%.',
    SoundEventType.batteryLow => 'Plays when battery drops below threshold.',
    SoundEventType.ringtone => 'Set as your phone ringtone.',
    SoundEventType.notification => 'Set as notification sound.',
    SoundEventType.alarm => 'Set as alarm tone.',
    SoundEventType.bootSound => 'Plays on device startup.',
    SoundEventType.smsTone => 'Plays for incoming messages.',
  };

  IconData get icon => switch (this) {
    SoundEventType.chargerIn => LucideIcons.zap,
    SoundEventType.chargerOut => LucideIcons.zapOff,
    SoundEventType.batteryFull => LucideIcons.batteryFull,
    SoundEventType.batteryLow => LucideIcons.batteryLow,
    SoundEventType.ringtone => LucideIcons.phone,
    SoundEventType.notification => LucideIcons.bell,
    SoundEventType.alarm => LucideIcons.alarmClock,
    SoundEventType.bootSound => LucideIcons.power,
    SoundEventType.smsTone => LucideIcons.messageCircle,
  };

  bool get isSystemDefault =>
      this == SoundEventType.ringtone ||
      this == SoundEventType.notification ||
      this == SoundEventType.alarm;
}
