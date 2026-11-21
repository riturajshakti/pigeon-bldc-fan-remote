package com.raj.pigeon_fan_remote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

private const val ACTION_SEND = "com.raj.pigeon_fan_remote.WIDGET_SEND"
private const val ACTION_SPEED = "com.raj.pigeon_fan_remote.WIDGET_SPEED"
private const val EXTRA_CODE = "code"
private const val EXTRA_LEVEL = "level"

class WidgetSkin(
    val layouts: IntArray,
    val arcs: IntArray,
    val arcId: Int,
    val nodeIds: IntArray,
    val powerId: Int,
    val boostId: Int,
    val nodeOff: Int,
    val nodeOn: Int,
    val textOff: Int,
    val textOn: Int,
    val boostOff: Int,
    val boostOnBg: Int,
    val boostIcon: Int,
    val boostIconOn: Int,
)

val solidSkin = WidgetSkin(
    layouts = intArrayOf(
        R.layout.fan_widget_s,
        R.layout.fan_widget_m,
        R.layout.fan_widget_l,
        R.layout.fan_widget_xl,
    ),
    arcs = intArrayOf(
        R.drawable.widget_arc_1,
        R.drawable.widget_arc_2,
        R.drawable.widget_arc_3,
        R.drawable.widget_arc_4,
        R.drawable.widget_arc_5,
    ),
    arcId = R.id.widget_arc,
    nodeIds = intArrayOf(
        R.id.widget_s1, R.id.widget_s2, R.id.widget_s3, R.id.widget_s4, R.id.widget_s5,
    ),
    powerId = R.id.widget_power,
    boostId = R.id.widget_boost,
    nodeOff = R.drawable.widget_node,
    nodeOn = R.drawable.widget_node_on,
    textOff = R.color.widget_on_surface,
    textOn = R.color.widget_on_accent,
    boostOff = R.drawable.widget_boost,
    boostOnBg = R.drawable.widget_boost_on,
    boostIcon = R.drawable.ic_w_boost,
    boostIconOn = R.drawable.ic_w_boost_on,
)

val transparentSkin = WidgetSkin(
    layouts = intArrayOf(
        R.layout.fan_widget_t_s,
        R.layout.fan_widget_t_m,
        R.layout.fan_widget_t_l,
        R.layout.fan_widget_t_xl,
    ),
    arcs = intArrayOf(
        R.drawable.widget_t_arc_1,
        R.drawable.widget_t_arc_2,
        R.drawable.widget_t_arc_3,
        R.drawable.widget_t_arc_4,
        R.drawable.widget_t_arc_5,
    ),
    arcId = R.id.t_widget_arc,
    nodeIds = intArrayOf(
        R.id.t_widget_s1, R.id.t_widget_s2, R.id.t_widget_s3,
        R.id.t_widget_s4, R.id.t_widget_s5,
    ),
    powerId = R.id.t_widget_power,
    boostId = R.id.t_widget_boost,
    nodeOff = R.drawable.widget_t_node,
    nodeOn = R.drawable.widget_t_node_on,
    textOff = R.color.widget_t_stroke,
    textOn = R.color.widget_t_text_on,
    boostOff = R.drawable.widget_t_boost,
    boostOnBg = R.drawable.widget_t_boost_on,
    boostIcon = R.drawable.ic_w_t_boost,
    boostIconOn = R.drawable.ic_w_t_boost_on,
)

abstract class BaseFanWidgetProvider : AppWidgetProvider() {

    abstract val skin: WidgetSkin

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
                    FanWidgetProvider.refreshAll(context)
                }
            }
            ACTION_SPEED -> {
                val level = intent.getIntExtra(EXTRA_LEVEL, -1)
                if (level !in 1..5) return
                FanIr.selectSpeed(context, level)
                FanState.setSpeed(context, level)
                FanWidgetProvider.refreshAll(context)
            }
        }
    }

    internal fun buildViews(context: Context, sideDp: Int): RemoteViews {
        val layout = when {
            sideDp < 135 -> skin.layouts[0]
            sideDp < 180 -> skin.layouts[1]
            sideDp < 235 -> skin.layouts[2]
            else -> skin.layouts[3]
        }
        val views = RemoteViews(context.packageName, layout)

        views.setOnClickPendingIntent(skin.powerId, commandIntent(context, FanIr.POWER))
        views.setOnClickPendingIntent(skin.boostId, commandIntent(context, FanIr.BOOST))

        val boostOn = FanState.boostOn(context)
        val level = if (boostOn) 5 else FanState.speed(context)

        for ((index, viewId) in skin.nodeIds.withIndex()) {
            val nodeLevel = index + 1
            views.setOnClickPendingIntent(viewId, speedIntent(context, nodeLevel))
            val on = nodeLevel <= level
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (on) skin.nodeOn else skin.nodeOff,
            )
            views.setTextColor(
                viewId,
                context.getColor(if (on) skin.textOn else skin.textOff),
            )
        }

        views.setImageViewResource(skin.arcId, skin.arcs[level - 1])

        views.setInt(
            skin.boostId,
            "setBackgroundResource",
            if (boostOn) skin.boostOnBg else skin.boostOff,
        )
        views.setImageViewResource(
            skin.boostId,
            if (boostOn) skin.boostIconOn else skin.boostIcon,
        )
        return views
    }

    private fun commandIntent(context: Context, code: Int): PendingIntent {
        val intent = Intent(context, javaClass).apply {
            action = ACTION_SEND
            putExtra(EXTRA_CODE, code)
        }
        return PendingIntent.getBroadcast(
            context,
            javaClass.name.hashCode() + code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun speedIntent(context: Context, level: Int): PendingIntent {
        val intent = Intent(context, javaClass).apply {
            action = ACTION_SPEED
            putExtra(EXTRA_LEVEL, level)
        }
        return PendingIntent.getBroadcast(
            context,
            javaClass.name.hashCode() + 1000 + level,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

class FanWidgetProvider : BaseFanWidgetProvider() {
    override val skin = solidSkin

    companion object {
        fun refreshAll(context: Context) {
            refreshFor(context, FanWidgetProvider(), FanWidgetProvider::class.java)
            refreshFor(
                context,
                FanWidgetTransparentProvider(),
                FanWidgetTransparentProvider::class.java,
            )
        }

        private fun refreshFor(
            context: Context,
            provider: BaseFanWidgetProvider,
            cls: Class<*>,
        ) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            for (id in ids) {
                manager.updateAppWidget(
                    id,
                    provider.buildViews(context, provider.sizeDp(manager, id)),
                )
            }
        }
    }
}

class FanWidgetTransparentProvider : BaseFanWidgetProvider() {
    override val skin = transparentSkin
}
