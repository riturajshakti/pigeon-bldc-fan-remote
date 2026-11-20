package com.raj.pigeon_fan_remote

import android.content.Context

object FanState {
    private fun prefs(context: Context) =
        context.getSharedPreferences("pigeon_fan_remote", Context.MODE_PRIVATE)

    fun speed(context: Context): Int =
        prefs(context).getInt("speed", 1).coerceIn(1, 5)

    fun boostOn(context: Context): Boolean =
        prefs(context).getBoolean("boostOn", false)

    fun setSpeed(context: Context, level: Int) {
        prefs(context).edit()
            .putInt("speed", level.coerceIn(1, 5))
            .putBoolean("boostOn", false)
            .apply()
    }

    fun setBoost(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean("boostOn", on).apply()
    }
}
