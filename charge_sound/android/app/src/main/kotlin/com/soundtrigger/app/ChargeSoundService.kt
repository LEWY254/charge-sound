package com.soundtrigger.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.MediaPlayer
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.File
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.sqrt

class ChargeSoundService : Service() {

    companion object {
        private const val NOTIF_ID = 1001
        private const val CHANNEL_ID = "charge_sound_channel"
        const val EXTRA_PLAY_BOOT_SOUND = "play_boot_sound"
        const val EXTRA_PLAY_NFC_SOUND = "play_nfc_sound"

        fun start(
            context: Context,
            playBootSound: Boolean = false,
            playNfcSound: Boolean = false,
        ) {
            val intent = Intent(context, ChargeSoundService::class.java).apply {
                if (playBootSound) putExtra(EXTRA_PLAY_BOOT_SOUND, true)
                if (playNfcSound) putExtra(EXTRA_PLAY_NFC_SOUND, true)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ChargeSoundService::class.java))
        }
    }

    private var eventReceiver: BroadcastReceiver? = null
    private var mediaPlayer: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    // Battery tracking
    private var lastBatteryLevel: Int = -1
    private var batteryLowTriggered = false
    private var batteryFullTriggered = false

    // Shake / face-down sensor
    private var sensorManager: SensorManager? = null
    private var lastShakeTime: Long = 0
    private var lastFaceDownTime: Long = 0
    private var faceDownCount = 0

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
        registerEventReceiver()
        registerSensors()

        when {
            intent?.getBooleanExtra(EXTRA_PLAY_BOOT_SOUND, false) == true ->
                playSoundForEvent("bootSound")
            intent?.getBooleanExtra(EXTRA_PLAY_NFC_SOUND, false) == true ->
                playSoundForEvent("nfcScanned")
        }

        return START_STICKY
    }

    override fun onDestroy() {
        unregisterEventReceiver()
        unregisterSensors()
        releasePlayer()
        super.onDestroy()
    }

    // ── Broadcast receiver ────────────────────────────────────────────────────

    private fun registerEventReceiver() {
        if (eventReceiver != null) return
        eventReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_POWER_CONNECTED -> playSoundForEvent("chargerIn")
                    Intent.ACTION_POWER_DISCONNECTED -> playSoundForEvent("chargerOut")
                    Intent.ACTION_BATTERY_CHANGED -> handleBatteryChanged(intent)
                    Intent.ACTION_HEADSET_PLUG -> handleHeadsetPlug(intent)
                    Intent.ACTION_SCREEN_ON -> playSoundForEvent("screenOn")
                    Intent.ACTION_SCREEN_OFF -> playSoundForEvent("screenOff")
                    Intent.ACTION_USER_PRESENT -> playSoundForEvent("deviceUnlocked")
                    Intent.ACTION_AIRPLANE_MODE_CHANGED -> handleAirplaneMode(intent)
                    PowerManager.ACTION_POWER_SAVE_MODE_CHANGED -> handleBatterySaver()
                    BluetoothDevice.ACTION_ACL_CONNECTED -> playSoundForEvent("bluetoothConnected")
                    BluetoothDevice.ACTION_ACL_DISCONNECTED -> playSoundForEvent("bluetoothDisconnected")
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_HEADSET_PLUG)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_AIRPLANE_MODE_CHANGED)
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(eventReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(eventReceiver, filter)
        }
    }

    private fun unregisterEventReceiver() {
        eventReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        eventReceiver = null
    }

    // ── Sensors ───────────────────────────────────────────────────────────────

    private val sensorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                handleAccelerometer(event)
            }
        }
        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
    }

    private fun registerSensors() {
        val sm = getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
        sensorManager = sm
        val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        sm.registerListener(sensorListener, accel, SensorManager.SENSOR_DELAY_NORMAL)
    }

    private fun unregisterSensors() {
        sensorManager?.unregisterListener(sensorListener)
        sensorManager = null
    }

    private fun handleAccelerometer(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val now = System.currentTimeMillis()

        // Shake: total magnitude significantly above gravity (9.8 m/s²)
        val magnitude = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
        if (magnitude > 18f && now - lastShakeTime > 1500) {
            lastShakeTime = now
            playSoundForEvent("phoneShaken")
        }

        // Face-down: Z-axis strongly negative, phone flat on table
        if (z < -8.5f && abs(x) < 3f && abs(y) < 3f) {
            faceDownCount++
            if (faceDownCount >= 4 && now - lastFaceDownTime > 3000) {
                lastFaceDownTime = now
                faceDownCount = 0
                playSoundForEvent("phoneFaceDown")
            }
        } else {
            faceDownCount = 0
        }
    }

    // ── Event-specific handlers ───────────────────────────────────────────────

    private fun handleBatteryChanged(intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        if (level < 0 || scale <= 0) return
        val percent = (level * 100) / scale

        if (percent >= 100 && !batteryFullTriggered) {
            batteryFullTriggered = true
            batteryLowTriggered = false
            playSoundForEvent("batteryFull")
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val threshold = prefs.getFloat("flutter.battery_threshold", 15f).toInt()

        if (percent < threshold && !batteryLowTriggered && lastBatteryLevel >= threshold) {
            batteryLowTriggered = true
            playSoundForEvent("batteryLow")
        }

        if (percent >= threshold) batteryLowTriggered = false
        if (percent < 100) batteryFullTriggered = false
        lastBatteryLevel = percent
    }

    private fun handleHeadsetPlug(intent: Intent) {
        when (intent.getIntExtra("state", -1)) {
            1 -> playSoundForEvent("headphonesIn")
            0 -> playSoundForEvent("headphonesOut")
        }
    }

    private fun handleAirplaneMode(intent: Intent) {
        if (intent.getBooleanExtra("state", false)) {
            playSoundForEvent("airplaneModeOn")
        } else {
            playSoundForEvent("airplaneModeOff")
        }
    }

    private fun handleBatterySaver() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (pm.isPowerSaveMode) playSoundForEvent("batterySaverOn")
        else playSoundForEvent("batterySaverOff")
    }

    // ── Sound playback ────────────────────────────────────────────────────────

    private fun playSoundForEvent(eventKey: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.service_enabled", true)) return

        val raw = prefs.getString("flutter.event_config", null) ?: return
        try {
            val config = JSONObject(raw)
            if (!config.has(eventKey)) return
            val soundObj = config.optJSONObject(eventKey) ?: return
            val path = soundObj.optString("path", "")
            val source = soundObj.optString("source", "")
            if (path.isEmpty()) return

            val resolvedPath = resolvePath(path, source, prefs) ?: return

            releasePlayer()
            val mp = MediaPlayer()
            mediaPlayer = mp

            val trimStartMs = soundObj.optInt("trimStartMs", 0).takeIf { it > 0 } ?: 0
            val trimEndMs = soundObj.optInt("trimEndMs", -1)
            val fadeInMs = soundObj.optLong("fadeInMs", 0)
            val fadeOutMs = soundObj.optLong("fadeOutMs", 0)

            mp.setDataSource(resolvedPath)
            mp.prepare()

            if (fadeInMs > 0) mp.setVolume(0f, 0f)
            if (trimStartMs > 0) mp.seekTo(trimStartMs)
            mp.start()
            if (fadeInMs > 0) applyFadeIn(mp, fadeInMs)

            val duration = mp.duration.toLong()
            val playDuration = when {
                trimEndMs > 0 && trimEndMs > trimStartMs -> (trimEndMs - trimStartMs).toLong()
                duration > 0 -> duration - trimStartMs
                else -> -1L
            }
            val maxPlaybackMs = prefs
                .getInt("flutter.event_playback_max_ms", 2000)
                .coerceAtLeast(250)
                .toLong()
            val effectiveDuration = if (playDuration > 0) {
                min(playDuration, maxPlaybackMs)
            } else {
                maxPlaybackMs
            }

            if (effectiveDuration > 0) {
                if (fadeOutMs > 0 && effectiveDuration > fadeOutMs) {
                    handler.postDelayed({
                        if (mediaPlayer === mp) applyFadeOut(mp, fadeOutMs)
                    }, effectiveDuration - fadeOutMs)
                }
                handler.postDelayed({
                    if (mediaPlayer === mp) releasePlayer()
                }, effectiveDuration)
            }

            mp.setOnCompletionListener { if (mediaPlayer === mp) releasePlayer() }
        } catch (e: Exception) {
            e.printStackTrace()
            releasePlayer()
        }
    }

    private fun resolvePath(
        path: String,
        source: String,
        prefs: android.content.SharedPreferences,
    ): String? = when {
        path.startsWith("http://") || path.startsWith("https://") -> path
        source == "meme" || path.startsWith("meme_sounds/") -> {
            val filename = path.substringAfterLast('/')
            val cached = File(cacheDir, "meme_sounds/$filename")
            if (cached.exists()) cached.absolutePath
            else {
                val supabaseUrl = prefs.getString("flutter.supabase_url", null)
                if (!supabaseUrl.isNullOrBlank())
                    "$supabaseUrl/storage/v1/object/public/meme-sounds/$filename"
                else null
            }
        }
        else -> File(path).takeIf { it.exists() }?.absolutePath
    }

    // ── Fade helpers ──────────────────────────────────────────────────────────

    private fun applyFadeIn(mp: MediaPlayer, durationMs: Long) {
        val steps = 20
        val interval = durationMs / steps
        var step = 0
        val r = object : Runnable {
            override fun run() {
                if (mediaPlayer !== mp) return
                step += 1
                val vol = (step.toFloat() / steps).coerceIn(0f, 1f)
                try { mp.setVolume(vol, vol) } catch (_: Exception) { return }
                if (step < steps) handler.postDelayed(this, interval)
            }
        }
        handler.postDelayed(r, interval)
    }

    private fun applyFadeOut(mp: MediaPlayer, durationMs: Long) {
        val steps = 20
        val interval = durationMs / steps
        var step = 0
        val r = object : Runnable {
            override fun run() {
                if (mediaPlayer !== mp) return
                step += 1
                val vol = (1f - step.toFloat() / steps).coerceIn(0f, 1f)
                try { mp.setVolume(vol, vol) } catch (_: Exception) { return }
                if (step < steps) handler.postDelayed(this, interval)
            }
        }
        handler.postDelayed(r, interval)
    }

    // ── Cleanup ───────────────────────────────────────────────────────────────

    private fun releasePlayer() {
        handler.removeCallbacksAndMessages(null)
        try { mediaPlayer?.release() } catch (_: Exception) {}
        mediaPlayer = null
    }

    // ── Notification ──────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Sound Trigger Service", NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps Sound Trigger active in the background"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sound Trigger")
            .setContentText("Listening for device events")
            .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
