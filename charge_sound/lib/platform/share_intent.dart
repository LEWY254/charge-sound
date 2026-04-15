import 'package:flutter/services.dart';

/// Handles the Android [Intent.ACTION_SEND] share-into-app flow.
class ShareIntentChannel {
  static const _channel = MethodChannel('com.soundtrigger.app/share');

  /// Returns the local file path of the shared audio, or null if the app
  /// was not launched via a share intent. Copies the content:// URI to a
  /// temp file inside the app cache so callers receive a plain file path.
  static Future<String?> getInitialSharedAudioPath() async {
    try {
      final path =
          await _channel.invokeMethod<String>('getSharedAudioPath');
      return path?.isEmpty == true ? null : path;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
