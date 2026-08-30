package com.zozugames.app

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Flutter [HapticFeedback] на Android — это View.performHapticFeedback
/// (KEYBOARD_TAP / CLOCK_TICK). На большинстве телефонов мотор молчит,
/// если в системе выключена «вибрация при касании».
/// Здесь — настоящий [Vibrator] с USAGE_NOTIFICATION.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "vibrate") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val raw = call.argument<List<*>>("pattern") ?: listOf(0, 50)
                    val pattern = raw.map { value ->
                        val n = when (value) {
                            is Number -> value.toInt()
                            else -> 0
                        }
                        n.coerceIn(0, 400).toLong()
                    }.toLongArray()
                    vibratePattern(pattern)
                    result.success(null)
                } catch (e: Throwable) {
                    result.error("vibrate", e.message, null)
                }
            }
    }

    private fun vibratePattern(times: LongArray) {
        val vibrator = defaultVibrator() ?: return
        if (!vibrator.hasVibrator()) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(times, -1)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val attrs = VibrationAttributes.Builder()
                        .setUsage(VibrationAttributes.USAGE_NOTIFICATION)
                        .build()
                    vibrator.vibrate(effect, attrs)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(effect, notificationAudioAttributes())
                }
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(times, -1)
            }
        } catch (_: Throwable) {
            // OEM без мотора / запрет системы — не роняем Activity.
        }
    }

    private fun defaultVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun notificationAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    companion object {
        private const val CHANNEL = "zozu/haptics"
    }
}
