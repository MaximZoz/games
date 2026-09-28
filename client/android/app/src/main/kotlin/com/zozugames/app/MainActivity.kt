package com.zozugames.app

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

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
        gamepadChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GAMEPAD_CHANNEL,
        )
        gamepadChannel?.setMethodCallHandler { call, result ->
                if (call.method != "listDevices") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    result.success(listGamepads())
                } catch (e: Throwable) {
                    result.error("gamepad", e.message, null)
                }
            }
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.isFromSource(InputDevice.SOURCE_JOYSTICK) ||
            event.isFromSource(InputDevice.SOURCE_GAMEPAD)
        ) {
            sendGamepadMotion(event)
        }
        return super.dispatchGenericMotionEvent(event)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val fromPad = event.device?.isGamepadLike() == true || event.isGamepadButton
        if (fromPad) {
            try {
                gamepadChannel?.invokeMethod(
                    "key",
                    hashMapOf(
                        "keyCode" to event.keyCode,
                        "down" to (event.action == KeyEvent.ACTION_DOWN),
                        "repeat" to event.repeatCount,
                    ),
                )
            } catch (_: Throwable) {
            }
            // DPAD с левого стика не должен дойти до IME/TextField — каретка
            // остаётся на месте, символы выбирает экранная клавиатура.
            if (event.isDpadDirection) {
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun sendGamepadMotion(event: MotionEvent) {
        val device = event.device
        val rx = pickAxis(event, MotionEvent.AXIS_Z, MotionEvent.AXIS_RX)
        val ry = pickAxis(event, MotionEvent.AXIS_RZ, MotionEvent.AXIS_RY)
        try {
            gamepadChannel?.invokeMethod(
                "motion",
                hashMapOf(
                    "id" to "android-${device?.id ?: 0}",
                    "name" to (device?.name?.trim().orEmpty().ifEmpty { "Gamepad" }),
                    "lx" to event.getAxisValue(MotionEvent.AXIS_X),
                    "ly" to event.getAxisValue(MotionEvent.AXIS_Y),
                    "rx" to rx,
                    "ry" to ry,
                    "hx" to event.getAxisValue(MotionEvent.AXIS_HAT_X),
                    "hy" to event.getAxisValue(MotionEvent.AXIS_HAT_Y),
                    "lt" to maxOf(
                        event.getAxisValue(MotionEvent.AXIS_LTRIGGER),
                        event.getAxisValue(MotionEvent.AXIS_BRAKE),
                    ),
                    "rt" to maxOf(
                        event.getAxisValue(MotionEvent.AXIS_RTRIGGER),
                        event.getAxisValue(MotionEvent.AXIS_GAS),
                    ),
                ),
            )
        } catch (_: Throwable) {
        }
    }

    private fun pickAxis(event: MotionEvent, a: Int, b: Int): Float {
        val va = event.getAxisValue(a)
        val vb = event.getAxisValue(b)
        return if (abs(va) >= abs(vb)) va else vb
    }

    private val KeyEvent.isDpadDirection: Boolean
        get() = keyCode == KeyEvent.KEYCODE_DPAD_LEFT ||
            keyCode == KeyEvent.KEYCODE_DPAD_RIGHT ||
            keyCode == KeyEvent.KEYCODE_DPAD_UP ||
            keyCode == KeyEvent.KEYCODE_DPAD_DOWN

    private val KeyEvent.isGamepadButton: Boolean
        get() = keyCode == KeyEvent.KEYCODE_BUTTON_A ||
            keyCode == KeyEvent.KEYCODE_BUTTON_B ||
            keyCode == KeyEvent.KEYCODE_BUTTON_X ||
            keyCode == KeyEvent.KEYCODE_BUTTON_Y ||
            keyCode == KeyEvent.KEYCODE_BUTTON_L1 ||
            keyCode == KeyEvent.KEYCODE_BUTTON_R1 ||
            keyCode == KeyEvent.KEYCODE_BUTTON_L2 ||
            keyCode == KeyEvent.KEYCODE_BUTTON_R2 ||
            keyCode == KeyEvent.KEYCODE_BUTTON_START ||
            keyCode == KeyEvent.KEYCODE_BUTTON_SELECT ||
            keyCode in KeyEvent.KEYCODE_BUTTON_1..KeyEvent.KEYCODE_BUTTON_16

    private fun InputDevice.isGamepadLike(): Boolean {
        if (isVirtual) return false
        val sources = sources
        return sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD ||
            sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
    }

    private fun listGamepads(): List<Map<String, Any>> {
        val out = ArrayList<Map<String, Any>>()
        for (id in InputDevice.getDeviceIds()) {
            val device = InputDevice.getDevice(id) ?: continue
            if (device.isVirtual) continue
            val sources = device.sources
            val gamepad = sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD
            val joystick = sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
            if (!gamepad && !joystick) continue
            val name = device.name?.trim().orEmpty().ifEmpty { "Gamepad" }
            out.add(
                hashMapOf(
                    "id" to "android-$id",
                    "name" to name,
                    "index" to id,
                ),
            )
        }
        return out
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
        private const val GAMEPAD_CHANNEL = "zozu/gamepad"
        private const val MAX_AMPLITUDE = 255
    }

    private var gamepadChannel: MethodChannel? = null
}
