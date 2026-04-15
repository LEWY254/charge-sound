package com.soundtrigger.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val serviceEnabled = prefs.getBoolean("flutter.service_enabled", true)
        if (serviceEnabled) {
            // Start the service and ask it to play the boot sound immediately.
            ChargeSoundService.start(context, playBootSound = true)
        }
    }
}
