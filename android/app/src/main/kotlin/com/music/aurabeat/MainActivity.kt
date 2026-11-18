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

/**
 * High-performance low-frequency sub-bass enhancement DSP processor with
 * steep biquad extraction, harmonic saturation, and anti-clipping headroom limiter.
 */
class DesktopSubBassEnhancer(private val sampleRate: Int = 48000) {
    @Volatile var enabled: Boolean = false
    @Volatile var intensity: Float = 0.50f
    @Volatile var frequencyHz: Float = 60.0f
    @Volatile var outputLevelDb: Float = 0.0f
    @Volatile var preset: String = "Natural Sub-Bass"

    private var z1 = 0.0f
    private var z2 = 0.0f

    fun process(samples: FloatArray, count: Int) {
        if (!enabled) return
        val linearGain = Math.pow(10.0, outputLevelDb.toDouble() / 20.0).toFloat() * intensity * 1.4f
        val omega = (2.0 * Math.PI * (frequencyHz / sampleRate).coerceIn(0.001f, 0.45f)).toFloat()
        val cosOmega = Math.cos(omega.toDouble()).toFloat()
        val alpha = (Math.sin(omega.toDouble()) / (2.0 * 0.85)).toFloat()
        val a0 = 1.0f + alpha
        val b0 = ((1.0f - cosOmega) * 0.5f) / a0
        val b1 = (1.0f - cosOmega) / a0
        val b2 = ((1.0f - cosOmega) * 0.5f) / a0
        val a1 = (-2.0f * cosOmega) / a0
        val a2 = (1.0f - alpha) / a0

        var index = 0
        while (index + 1 < count) {
            val left = samples[index]
            val right = samples[index + 1]
            val mono = (left + right) * 0.5f

            val sub = b0 * mono + z1
            z1 = b1 * mono - a1 * sub + z2
            z2 = b2 * mono - a2 * sub

            val driven = sub * (1.0f + intensity * 1.5f)
            val saturated = driven / (1.0f + Math.abs(driven))
            val addedSub = saturated * linearGain

            samples[index] = softLimit(left + addedSub)
            samples[index + 1] = softLimit(right + addedSub)
            index += 2
        }
    }

    private fun softLimit(x: Float): Float {
        val absX = Math.abs(x)
        if (absX <= 0.86f) return x
        val excess = absX - 0.86f
        val compressed = 0.86f + 0.14f * (excess / (1.0f + excess))
        return if (x < 0f) -compressed else compressed
    }

    fun reset() {
        z1 = 0.0f
        z2 = 0.0f
    }
}

class MainActivity : FlutterActivity() {
    private val channelName = "com.aurabeat.audio/quality"
    private val spatialAudio = DesktopSpatialAudio(channels = 2, sampleRate = 48000)
    private val subBassEnhancer = DesktopSubBassEnhancer(sampleRate = 48000)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences("aurabeat_audio_prefs", MODE_PRIVATE)
        subBassEnhancer.enabled = prefs.getBoolean("sub_bass_enabled", false)
        subBassEnhancer.intensity = prefs.getFloat("sub_bass_intensity", 0.50f)
        subBassEnhancer.frequencyHz = prefs.getFloat("sub_bass_frequency", 60.0f)
        subBassEnhancer.outputLevelDb = prefs.getFloat("sub_bass_output_level", 0.0f)
        subBassEnhancer.preset = prefs.getString("sub_bass_preset", "Natural Sub-Bass") ?: "Natural Sub-Bass"

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
                "setSubBassEnhancement" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) {
                        val enabled = (args["enabled"] as? Boolean) ?: false
                        val intensity = ((args["intensity"] as? Number)?.toFloat()) ?: 0.50f
                        val frequencyHz = ((args["frequencyHz"] as? Number)?.toFloat()) ?: 60.0f
                        val outputLevelDb = ((args["outputLevelDb"] as? Number)?.toFloat()) ?: 0.0f
                        val preset = (args["preset"] as? String) ?: "Natural Sub-Bass"

                        subBassEnhancer.enabled = enabled
                        subBassEnhancer.intensity = intensity
                        subBassEnhancer.frequencyHz = frequencyHz
                        subBassEnhancer.outputLevelDb = outputLevelDb
                        subBassEnhancer.preset = preset

                        prefs.edit()
                            .putBoolean("sub_bass_enabled", enabled)
                            .putFloat("sub_bass_intensity", intensity)
                            .putFloat("sub_bass_frequency", frequencyHz)
                            .putFloat("sub_bass_output_level", outputLevelDb)
                            .putString("sub_bass_preset", preset)
                            .apply()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "getSubBassConfiguration" -> {
                    result.success(mapOf(
                        "enabled" to subBassEnhancer.enabled,
                        "intensity" to subBassEnhancer.intensity.toDouble(),
                        "frequencyHz" to subBassEnhancer.frequencyHz.toDouble(),
                        "outputLevelDb" to subBassEnhancer.outputLevelDb.toDouble(),
                        "preset" to subBassEnhancer.preset
                    ))
                }
                "resetSubBassConfiguration" -> {
                    subBassEnhancer.enabled = false
                    subBassEnhancer.intensity = 0.50f
                    subBassEnhancer.frequencyHz = 60.0f
                    subBassEnhancer.outputLevelDb = 0.0f
                    subBassEnhancer.preset = "Natural Sub-Bass"
                    subBassEnhancer.reset()

                    prefs.edit()
                        .putBoolean("sub_bass_enabled", false)
                        .putFloat("sub_bass_intensity", 0.50f)
                        .putFloat("sub_bass_frequency", 60.0f)
                        .putFloat("sub_bass_output_level", 0.0f)
                        .putString("sub_bass_preset", "Natural Sub-Bass")
                        .apply()
                    result.success(true)
                }
                "getPipelineTelemetry" -> {
                    result.success(mapOf(
                        "spatialEnabled" to spatialAudio.enabled,
                        "subBassEnabled" to subBassEnhancer.enabled,
                        "subBassIntensity" to subBassEnhancer.intensity.toDouble(),
                        "subBassFrequency" to subBassEnhancer.frequencyHz.toDouble(),
                        "deviceName" to "Android AudioTrack Output",
                        "realtimeTapActive" to false
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }
}
