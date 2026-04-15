package com.soundtrigger.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.io.File

/**
 * Plays the configured "smsTone" sound when an SMS is received.
 * Uses a static [MediaPlayer] shared across invocations so that a burst of
 * messages doesn't stack up multiple simultaneous plays.
 */
class SmsReceiver : BroadcastReceiver() {

    companion object {
        private var mediaPlayer: MediaPlayer? = null
        private val handler = Handler(Looper.getMainLooper())
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "android.provider.Telephony.SMS_RECEIVED") return

        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val serviceEnabled = prefs.getBoolean("flutter.service_enabled", true)
        if (!serviceEnabled) return

        val raw = prefs.getString("flutter.event_config", null) ?: return

        try {
            val config = JSONObject(raw)
            if (!config.has("smsTone")) return
            val soundObj = config.optJSONObject("smsTone") ?: return
            val path = soundObj.optString("path", "")
            val source = soundObj.optString("source", "")
            if (path.isEmpty()) return

            val resolvedPath = resolvePath(path, source, prefs, context) ?: return

            handler.post {
                mediaPlayer?.release()
                mediaPlayer = null
                val mp = MediaPlayer()
                mediaPlayer = mp
                try {
                    mp.setDataSource(resolvedPath)
                    mp.prepare()
                    mp.start()
                    val maxPlaybackMs = prefs
                        .getInt("flutter.event_playback_max_ms", 2000)
                        .coerceAtLeast(250)
                        .toLong()
                    handler.postDelayed({
                        if (mediaPlayer === mp) {
                            mp.release()
                            mediaPlayer = null
                        }
                    }, maxPlaybackMs)
                    mp.setOnCompletionListener {
                        mp.release()
                        if (mediaPlayer === mp) mediaPlayer = null
                    }
                } catch (e: Exception) {
                    mp.release()
                    if (mediaPlayer === mp) mediaPlayer = null
                }
            }
        } catch (_: Exception) {}
    }

    private fun resolvePath(
        path: String,
        source: String,
        prefs: android.content.SharedPreferences,
        context: Context,
    ): String? {
        return when {
            path.startsWith("http://") || path.startsWith("https://") -> path
            source == "meme" || path.startsWith("meme_sounds/") -> {
                val filename = path.substringAfterLast('/')
                val cached = File(context.cacheDir, "meme_sounds/$filename")
                if (cached.exists()) {
                    cached.absolutePath
                } else {
                    val supabaseUrl = prefs.getString("flutter.supabase_url", null)
                    if (!supabaseUrl.isNullOrBlank()) {
                        "$supabaseUrl/storage/v1/object/public/meme-sounds/$filename"
                    } else {
                        null
                    }
                }
            }
            else -> {
                val f = File(path)
                if (f.exists()) f.absolutePath else null
            }
        }
    }
}
