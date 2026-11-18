package com.music.aurabeat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * Desktop Spatial Audio implementation ported directly from BitChord Desktop 1.8.
 * (DesktopAudioProcessors.kt: DesktopSpatialAudio).
 */
class DesktopSpatialAudio(private val channels: Int, sampleRate: Int) {
    @Volatile
    var enabled: Boolean = false

    val applies: Boolean = channels == 2

    private val widthGain = 2.5f
    private val outputGain = 0.82f
    private val crossfeedGain = 0.2f
    private val lowpassCoeff = 0.3f

    private val delayFrames = (sampleRate * DELAY_MS / 1000f).roundToInt().coerceAtLeast(1)
    private var delayLeft = FloatArray(delayFrames)
    private var delayRight = FloatArray(delayFrames)
    private var delayIndex = 0
    private var lowpassLeft = 0f
    private var lowpassRight = 0f

    fun process(samples: FloatArray, count: Int) {
        if (!enabled || !applies) return
        var index = 0
        while (index + 1 < count) {
            val left = samples[index]
            val right = samples[index + 1]

            val mid = (left + right) * 0.5f
            val side = (left - right) * 0.5f * widthGain
            var widenedLeft = mid + side
            var widenedRight = mid - side

            lowpassLeft += lowpassCoeff * (delayRight[delayIndex] - lowpassLeft)
            lowpassRight += lowpassCoeff * (delayLeft[delayIndex] - lowpassRight)
            widenedLeft += lowpassLeft * crossfeedGain
            widenedRight += lowpassRight * crossfeedGain

            delayLeft[delayIndex] = left
            delayRight[delayIndex] = right
            delayIndex = (delayIndex + 1) % delayFrames

            samples[index] = widenedLeft * outputGain
            samples[index + 1] = widenedRight * outputGain
            index += 2
        }
    }

    fun reset() {
        delayLeft.fill(0f)
        delayRight.fill(0f)
        delayIndex = 0
        lowpassLeft = 0f
        lowpassRight = 0f
    }

    companion object {
        const val DELAY_MS = 15
    }
}

class MainActivity : FlutterActivity() {
    private val channelName = "com.aurabeat.audio/quality"
    private val spatialAudio = DesktopSpatialAudio(channels = 2, sampleRate = 48000)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSpatialAudio" -> {
                    val enabled = (call.arguments as? Boolean) ?: false
                    spatialAudio.enabled = enabled
                    result.success(true)
                }
                "setSpatial" -> {
                    val enabled = when (val args = call.arguments) {
                        is Boolean -> args
                        is Map<*, *> -> (args["enabled"] as? Boolean) ?: false
                        else -> false
                    }
                    spatialAudio.enabled = enabled
                    result.success(true)
                }
                "getPipelineTelemetry" -> {
                    result.success(mapOf(
                        "spatialEnabled" to spatialAudio.enabled,
                        "deviceName" to "Android AudioTrack Output",
                        "realtimeTapActive" to false
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }
}
