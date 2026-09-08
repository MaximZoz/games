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
/// Здесь — настоящий [Vibrator] с USAGE_TOUCH / USAGE_GAME (не notification).
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
                        n.coerceIn(0, 800).toLong()
                    }.toLongArray()
                    result.success(vibratePattern(pattern))
                } catch (e: Throwable) {
                    result.error("vibrate", e.message, null)
                }
            }
    }

    private fun vibratePattern(times: LongArray): Boolean {
        val vibrator = defaultVibrator() ?: return false
        if (!vibrator.hasVibrator()) return false
        if (times.isEmpty() || times.sum() <= 0L) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = waveformEffect(vibrator, times)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (vibrateWithTouch(vibrator, effect)) return true
            }
            if (vibrateWithGameAudio(vibrator, effect)) return true
            return try {
                vibrator.vibrate(effect)
                true
            } catch (_: Throwable) {
                false
            }
        }
        return try {
            @Suppress("DEPRECATION")
            vibrator.vibrate(times, -1)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun vibrateWithTouch(vibrator: Vibrator, effect: VibrationEffect): Boolean {
        return try {
            val attrs = VibrationAttributes.Builder()
                .setUsage(VibrationAttributes.USAGE_TOUCH)
                .build()
            vibrator.vibrate(effect, attrs)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun vibrateWithGameAudio(vibrator: Vibrator, effect: VibrationEffect): Boolean {
        return try {
            @Suppress("DEPRECATION")
            vibrator.vibrate(effect, gameAudioAttributes())
            true
        } catch (_: Throwable) {
            false
        }
    }

    /// Короткий импульс «ваш ход» на LRA почти не чувствуется при амплитуде
    /// по умолчанию — где можно, выдаём максимальную силу.
    private fun waveformEffect(vibrator: Vibrator, times: LongArray): VibrationEffect {
        if (!vibrator.hasAmplitudeControl()) {
            return VibrationEffect.createWaveform(times, -1)
        }
        val amplitudes = IntArray(times.size) { index ->
            if (index % 2 == 0) 0 else MAX_AMPLITUDE
        }
        return VibrationEffect.createWaveform(times, amplitudes, -1)
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

    private fun gameAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    companion object {
        private const val CHANNEL = "zozu/haptics"
        private const val MAX_AMPLITUDE = 255
    }
}
