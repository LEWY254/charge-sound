import 'package:flutter/services.dart';

/// Android-only channel for [Settings.System.canWrite] and opening
/// [Settings.ACTION_MANAGE_WRITE_SETTINGS]. No-op / false on other platforms.
class AndroidWriteSettings {
  static const _channel = MethodChannel('com.soundtrigger.app/settings');

  static Future<bool> canWriteSettings() async {
    try {
      final v = await _channel.invokeMethod<bool>('canWriteSettings');
      return v ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> openWriteSettingsScreen() async {
    try {
      await _channel.invokeMethod<void>('openWriteSettings');
    } on MissingPluginException {
      // iOS / tests
    }
  }

  static Future<void> openSystemSoundSettings() async {
    try {
      await _channel.invokeMethod<void>('openSystemSoundSettings');
    } on MissingPluginException {
      // iOS / tests
    }
  }

  static Future<SystemSoundApplyResult> setSystemDefaultSound({
    required String eventType,
    required String soundPath,
    required String soundName,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'setSystemDefaultSound',
        <String, Object?>{
          'eventType': eventType,
          'soundPath': soundPath,
          'soundName': soundName,
        },
      );
      final map = raw == null
          ? const <Object?, Object?>{}
          : Map<Object?, Object?>.from(raw);
      return SystemSoundApplyResult(
        success: map['success'] == true,
        message: (map['message'] as String?) ?? 'No response from platform.',
      );
    } on MissingPluginException {
      return const SystemSoundApplyResult(
        success: false,
        message: 'System sound assignment is only available on Android devices.',
      );
    } on PlatformException catch (e) {
      return SystemSoundApplyResult(
        success: false,
        message: e.message ?? 'Failed to set system sound.',
      );
    } catch (e) {
      return SystemSoundApplyResult(
        success: false,
        message: 'Failed to set system sound: $e',
      );
    }
  }
}

class SystemSoundApplyResult {
  const SystemSoundApplyResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}
