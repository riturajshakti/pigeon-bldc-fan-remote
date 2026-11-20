package com.raj.pigeon_fan_remote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.widget.RemoteViews

private const val ACTION_SEND = "com.raj.pigeon_fan_remote.WIDGET_SEND"
private const val ACTION_SPEED = "com.raj.pigeon_fan_remote.WIDGET_SPEED"
private const val EXTRA_CODE = "code"
private const val EXTRA_LEVEL = "level"

class FanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            manager.updateAppWidget(id, buildViews(context, sizeDp(manager, id)))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, manager, appWidgetId, newOptions)
        manager.updateAppWidget(appWidgetId, buildViews(context, sizeDp(manager, appWidgetId)))
    }

    internal fun sizeDp(manager: AppWidgetManager, id: Int): Int {
        val o = manager.getAppWidgetOptions(id)
        val w = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val h = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val side = if (w > 0 && h > 0) minOf(w, h) else maxOf(w, h)
        return if (side > 0) side else 150
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_SEND -> {
                val code = intent.getIntExtra(EXTRA_CODE, -1)
                if (code < 0) return
                if (FanIr.send(context, code) && code == FanIr.BOOST) {
                    FanState.setBoost(context, true)
                    refreshAll(context)
                }
            }
            ACTION_SPEED -> {
                val level = intent.getIntExtra(EXTRA_LEVEL, -1)
                if (level !in 1..5) return
                FanIr.selectSpeed(context, level)
                FanState.setSpeed(context, level)
                refreshAll(context)
            }
        }
    }

    private fun refreshAll(context: Context) = Companion.refreshAll(context)

    companion object {
        fun refreshAll(context: Context) {
            val provider = FanWidgetProvider()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FanWidgetProvider::class.java)
            )
            for (id in ids) {
                manager.updateAppWidget(
                    id,
                    provider.buildViews(context, provider.sizeDp(manager, id)),
                )
            }
        }
    }

    internal fun buildViews(context: Context, sideDp: Int): RemoteViews {
        val layout = when {
            sideDp < 135 -> R.layout.fan_widget_s
            sideDp < 180 -> R.layout.fan_widget_m
            sideDp < 235 -> R.layout.fan_widget_l
            else -> R.layout.fan_widget_xl
        }
        val views = RemoteViews(context.packageName, layout)

        views.setOnClickPendingIntent(R.id.widget_power, commandIntent(context, FanIr.POWER))
        views.setOnClickPendingIntent(R.id.widget_boost, commandIntent(context, FanIr.BOOST))

        val boostOn = FanState.boostOn(context)
        val level = if (boostOn) 5 else FanState.speed(context)

        val nodes = listOf(
            R.id.widget_s1 to 1,
            R.id.widget_s2 to 2,
            R.id.widget_s3 to 3,
            R.id.widget_s4 to 4,
            R.id.widget_s5 to 5,
        )
        for ((viewId, nodeLevel) in nodes) {
            views.setOnClickPendingIntent(viewId, speedIntent(context, nodeLevel))
            val on = nodeLevel <= level
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (on) R.drawable.widget_node_on else R.drawable.widget_node,
            )
            views.setTextColor(
                viewId,
                context.getColor(
                    if (on) R.color.widget_on_accent else R.color.widget_on_surface
                ),
            )
        }

        views.setImageViewResource(
            R.id.widget_arc,
            when (level) {
                2 -> R.drawable.widget_arc_2
                3 -> R.drawable.widget_arc_3
                4 -> R.drawable.widget_arc_4
                5 -> R.drawable.widget_arc_5
                else -> R.drawable.widget_arc_1
            },
        )

        views.setInt(
            R.id.widget_boost,
            "setBackgroundResource",
            if (boostOn) R.drawable.widget_boost_on else R.drawable.widget_boost,
        )
        views.setImageViewResource(
            R.id.widget_boost,
            if (boostOn) R.drawable.ic_w_boost_on else R.drawable.ic_w_boost,
        )
        return views
    }

    private fun commandIntent(context: Context, code: Int): PendingIntent {
        val intent = Intent(context, FanWidgetProvider::class.java).apply {
            action = ACTION_SEND
            putExtra(EXTRA_CODE, code)
        }
        return PendingIntent.getBroadcast(
            context,
            code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun speedIntent(context: Context, level: Int): PendingIntent {
        val intent = Intent(context, FanWidgetProvider::class.java).apply {
            action = ACTION_SPEED
            putExtra(EXTRA_LEVEL, level)
        }
        return PendingIntent.getBroadcast(
            context,
            1000 + level,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
