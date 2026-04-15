import 'package:flutter/services.dart';

/// Controls the native Android foreground service that listens for
/// charger plug/unplug events and plays the configured sounds.
class ChargeSoundServiceChannel {
  static const _channel = MethodChannel('com.soundtrigger.app/charge_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } on PlatformException catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (_) {}
  }
}
