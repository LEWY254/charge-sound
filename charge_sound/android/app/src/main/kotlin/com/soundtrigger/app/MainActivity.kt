package com.soundtrigger.app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.nfc.NfcAdapter
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.media.RingtoneManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.net.URL
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val channelName = "com.soundtrigger.app/settings"
    private val shareChannel = "com.soundtrigger.app/share"
    private val serviceChannel = "com.soundtrigger.app/charge_service"

    private fun isNfcIntent(intent: Intent?): Boolean {
        val action = intent?.action ?: return false
        return action == NfcAdapter.ACTION_TAG_DISCOVERED ||
            action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            action == NfcAdapter.ACTION_TECH_DISCOVERED
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isNfcIntent(intent)) {
            ChargeSoundService.start(this, playNfcSound = true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Handle NFC tag that launched the app cold.
        if (isNfcIntent(intent)) {
            ChargeSoundService.start(this, playNfcSound = true)
        }
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            serviceChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    ChargeSoundService.start(this)
                    result.success(null)
                }
                "stop" -> {
                    ChargeSoundService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canWriteSettings" -> {
                    result.success(Settings.System.canWrite(this))
                }
                "openWriteSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "openSystemSoundSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_SOUND_SETTINGS))
                        result.success(null)
                    } catch (e: Exception) {
                        Toast.makeText(
                            this,
                            "Could not open sound settings",
                            Toast.LENGTH_SHORT,
                        ).show()
                        result.error("OPEN_SOUND_SETTINGS_FAILED", e.message, null)
                    }
                }
                "setSystemDefaultSound" -> {
                    applySystemDefaultSound(call, result)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shareChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedAudio" -> {
                    result.success(extractSharedAudioUri(intent))
                }
                "getSharedAudioPath" -> {
                    result.success(copySharedAudioToCache(intent))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copySharedAudioToCache(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND) return null
        val type = intent.type ?: return null
        if (!type.startsWith("audio/")) return null
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: return null
        return try {
            val ext = when {
                type.contains("wav") -> ".wav"
                type.contains("ogg") -> ".ogg"
                type.contains("aac") -> ".aac"
                type.contains("mp4") -> ".m4a"
                else -> ".mp3"
            }
            val dest = java.io.File(cacheDir, "shared_import_${System.currentTimeMillis()}$ext")
            contentResolver.openInputStream(uri)?.use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            dest.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun extractSharedAudioUri(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND) return null
        val type = intent.type ?: return null
        if (!type.startsWith("audio/")) return null
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        return uri?.toString()
    }

    private fun applySystemDefaultSound(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            if (!Settings.System.canWrite(this)) {
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "System settings permission is not granted.",
                    ),
                )
                return
            }

            val eventType = call.argument<String>("eventType")
            val soundPath = call.argument<String>("soundPath")
            val soundName = call.argument<String>("soundName")

            if (eventType.isNullOrBlank() || soundPath.isNullOrBlank() || soundName.isNullOrBlank()) {
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Missing sound configuration.",
                    ),
                )
                return
            }

            val ringtoneType = when (eventType) {
                "ringtone" -> RingtoneManager.TYPE_RINGTONE
                "notification" -> RingtoneManager.TYPE_NOTIFICATION
                "alarm" -> RingtoneManager.TYPE_ALARM
                else -> {
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Unsupported system default type: $eventType",
                        ),
                    )
                    return
                }
            }

            val uri = prepareAudioInMediaStore(
                sourcePath = soundPath,
                soundName = soundName,
                ringtoneType = ringtoneType,
            )

            if (uri == null) {
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Could not prepare the selected audio file.",
                    ),
                )
                return
            }

            RingtoneManager.setActualDefaultRingtoneUri(this, ringtoneType, uri)
            result.success(
                mapOf(
                    "success" to true,
                    "message" to "System sound updated.",
                ),
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to (e.message ?: "Failed to set system sound."),
                ),
            )
        }
    }

    private fun prepareAudioInMediaStore(
        sourcePath: String,
        soundName: String,
        ringtoneType: Int,
    ): Uri? {
        val extension = sourcePath.substringAfterLast('.', "mp3")
            .lowercase(Locale.US)
            .ifBlank { "mp3" }
        val mimeType = when (extension) {
            "wav" -> "audio/wav"
            "ogg" -> "audio/ogg"
            "aac" -> "audio/aac"
            "m4a" -> "audio/mp4"
            "flac" -> "audio/flac"
            else -> "audio/mpeg"
        }
        val safeName = soundName.replace(Regex("[^A-Za-z0-9._-]+"), "_")
        val displayName = "${safeName}_${System.currentTimeMillis()}.$extension"

        val input = when {
            sourcePath.startsWith("assets/") -> {
                assets.open("flutter_assets/$sourcePath")
            }
            sourcePath.startsWith("http://") || sourcePath.startsWith("https://") -> {
                URL(sourcePath).openStream()
            }
            else -> {
                val f = File(sourcePath)
                if (!f.exists()) return null
                FileInputStream(f)
            }
        }

        input.use { source ->
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
                put(MediaStore.Audio.Media.IS_MUSIC, false)
                put(MediaStore.Audio.Media.IS_RINGTONE, ringtoneType == RingtoneManager.TYPE_RINGTONE)
                put(MediaStore.Audio.Media.IS_NOTIFICATION, ringtoneType == RingtoneManager.TYPE_NOTIFICATION)
                put(MediaStore.Audio.Media.IS_ALARM, ringtoneType == RingtoneManager.TYPE_ALARM)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val relativePath = when (ringtoneType) {
                        RingtoneManager.TYPE_NOTIFICATION -> Environment.DIRECTORY_NOTIFICATIONS
                        RingtoneManager.TYPE_ALARM -> Environment.DIRECTORY_ALARMS
                        else -> Environment.DIRECTORY_RINGTONES
                    }
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }

            val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            val uri = resolver.insert(collection, values) ?: return null
            try {
                resolver.openOutputStream(uri)?.use { out ->
                    source.copyTo(out)
                } ?: run {
                    resolver.delete(uri, null, null)
                    return null
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val ready = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                    resolver.update(uri, ready, null, null)
                }
                return uri
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
        }
    }
}
