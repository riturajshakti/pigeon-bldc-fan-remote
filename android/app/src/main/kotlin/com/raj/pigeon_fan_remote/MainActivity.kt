package com.raj.pigeon_fan_remote

import android.content.Context
import android.hardware.ConsumerIrManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "com.raj.pigeon_fan_remote/ir"

class MainActivity : FlutterActivity() {

    private val irManager: ConsumerIrManager?
        get() = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager

    private val prefs by lazy {
        getSharedPreferences("pigeon_fan_remote", Context.MODE_PRIVATE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasIrEmitter" -> result.success(irManager?.hasIrEmitter() ?: false)
                    "getCarrierFrequencies" -> result.success(carrierFrequencies())
                    "transmit" -> transmit(call.argument("frequency"), call.argument("pattern"), result)
                    "loadPrefs" -> result.success(
                        mapOf(
                            "speed" to prefs.getInt("speed", -1),
                            "theme" to prefs.getString("theme", null),
                            "boostOn" to prefs.getBoolean("boostOn", false),
                        )
                    )
                    "savePrefs" -> {
                        prefs.edit().apply {
                            call.argument<Int>("speed")?.let { putInt("speed", it) }
                            call.argument<String>("theme")?.let { putString("theme", it) }
                            call.argument<Boolean>("boostOn")?.let { putBoolean("boostOn", it) }
                        }.apply()
                        FanWidgetProvider.refreshAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun carrierFrequencies(): List<Map<String, Int>> {
        val ir = irManager ?: return emptyList()
        if (!ir.hasIrEmitter()) return emptyList()
        return ir.carrierFrequencies?.map {
            mapOf("min" to it.minFrequency, "max" to it.maxFrequency)
        } ?: emptyList()
    }

    private fun transmit(frequency: Int?, pattern: List<Int>?, result: MethodChannel.Result) {
        val ir = irManager
        if (ir == null || !ir.hasIrEmitter()) {
            result.error("NO_EMITTER", "This device has no IR emitter", null)
            return
        }
        if (frequency == null || pattern == null || pattern.isEmpty()) {
            result.error("BAD_ARGS", "frequency and a non-empty pattern are required", null)
            return
        }
        if (pattern.any { it <= 0 }) {
            result.error("BAD_ARGS", "pattern durations must all be positive", null)
            return
        }
        try {
            ir.transmit(frequency, pattern.toIntArray())
            result.success(null)
        } catch (e: Exception) {
            result.error("TRANSMIT_FAILED", e.message, null)
        }
    }
}
