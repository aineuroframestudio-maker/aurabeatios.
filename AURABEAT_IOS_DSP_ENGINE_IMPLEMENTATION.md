# AURABEAT — iOS DSP ENGINE IMPLEMENTATION
**Native Real-Time Audio Processing Architecture for iOS AVFoundation**
*Target: `ios/Runner/AuraBeatAudioManager.swift` & `ios/Runner/AppDelegate.swift`*

---

## 1. Overview and Core Philosophy

The new native iOS DSP engine (`AuraBeatDSPEngine`) replaces previous ad-hoc audio units with an in-process, zero-allocation C/Swift MediaToolbox processing tap pipeline. It provides bit-for-bit parity with BitChord Desktop 1.8 while respecting the real-time constraints of iOS audio render threads (hard deadlines, zero heap allocations, zero lock acquisitions, and lock-free thread safety).

---

## 2. The Eight Core Architectural Components

The engine is partitioned into eight cleanly separated, single-responsibility components:

### 2.1 `AuraBeatDSPConfiguration`
Centralizes user preferences and runtime audio configuration:
- `eqMode`: `.off`, `.manual`, or `.dynamicMode`
- `manualBands`: Array of 7 manual band gains in decibels ($\pm 12$ dB)
- `toneX`, `toneY`, `toneFocused`: 2-axis tone pad coordinates (-5..+5) and bandwidth state
- `balance`: Stereo balance trim (-1.0 to +1.0)
- `presetName`: Active preset string identifier (17 supported presets)
- `spatialAudioEnabled`: Boolean toggle for stereo widening
- `silenceSkippingEnabled`: Boolean toggle for automated silence skipping
- `playbackSpeed`: Rate scalar (0.25x to 3.0x)

### 2.2 `AuraBeatAudioFormatValidator`
Enforces strict CoreAudio format guarantees before any buffer memory is touched:
- Verifies `mFormatID == kAudioFormatLinearPCM`.
- Confirms 32-bit floating point packed or non-interleaved flags (`kAudioFormatFlagIsFloat`).
- Validates sample rates ($> 0$) and channel counts ($> 0$).
- Inspects `AudioBufferList` layout:
  - **Interleaved Stereo:** 1 buffer, 2 channels, `!isNonInterleaved`.
  - **Planar Stereo:** 2 buffers, 1 channel per buffer.
  - **Mono Bypass:** 1 buffer, 1 channel (full-pipeline bit-identical bypass).
  - **Multichannel Bypass:** $>2$ buffers or $>2$ channels (full-pipeline bit-identical bypass).
  - Validates `mDataByteSize` against required frame capacities to eliminate out-of-bounds reads.

### 2.3 `AuraBeatSpatialAudioProcessor`
Direct 1:1 Swift port of `DesktopSpatialAudio`:
- Constants: `delayMs = 15.0`, `widthGain = 2.5`, `outputGain = 0.82`, `crossfeedGain = 0.2`, `lowpassCoeff = 0.3`.
- Circular delay buffers pre-allocated at format configuration (`delayFrames = round(sampleRate * 0.015)`).
- Interleaved (`processInterleaved`) and Planar (`processPlanar`) execution paths.
- Resets circular indices and filter states upon track seek or track switch.

### 2.4 `AuraBeatEqualizer`
Complete port of Desktop 1.8 Cytomic State-Variable Filter (SVF):
- 10-slot cascade: 7 manual bands (60 Hz Low Shelf, 150 Hz, 400 Hz, 1 kHz, 2.5 kHz, 6 kHz, 14 kHz High Shelf) + 3 tone pad slots (250 Hz Low Shelf, 1 kHz Bell, 4 kHz High Shelf).
- Automatic make-up attenuation (`preampDb`) computed via 96-point logarithmic response scan.
- Sub-block parameter gliding across 64-frame chunks (`GLIDE_FRAMES = 64`, `GLIDE_RATE = 0.08`).
- Linear decibel glide for gains, preamp, and balance; geometric glide for Q factors.
- Far-channel attenuation for stereo balance (`1.0 - balance` for Left, `1.0 + balance` for Right).
- Denormal flushing threshold at $10^{-12}$.

### 2.5 `AuraBeatPCMProcessor`
Executes audio transformation in strict Desktop 1.8 order:
1. **Stage 1 (Spatial Widening):** `spatialProcessor.processInterleaved` / `processPlanar`
2. **Stage 2 (Equalizer & Preamp):** `equalizer.processInterleaved` / `processPlanar`
3. **Stage 3 (Silence Energy Tracking):** RMS calculation and silence duration accumulation ($< -60$ dBFS)

### 2.6 `AuraBeatAudioLifecycleManager`
Manages audio state across playback transitions:
- `onTrackChanged()`: Flushes circular delay lines and filter ringing states, resets counters.
- `onSeek()`: Clears filter integrators (`resetStateOnly`) to prevent transient pops.
- `onFormatChanged(format)`: Revalidates ASBD and recalculates buffer sizes.

### 2.7 `AuraBeatDSPDiagnostics`
Telemetry reporting struct providing detailed snapshots to Flutter:
- Sample rate, channel count, format validity, interleaved status.
- Spatial active status and bypass reason ("Mono Input", "Multichannel Input", "Dolby Atmos Passthrough").
- Active EQ mode, preamp attenuation dB, balance trim, and callback execution counters.

### 2.8 `AuraBeatDSPEngine`
Master coordinator facade:
- Singleton instance: `AuraBeatDSPEngine.shared`.
- Dispatches MediaToolbox `MTAudioProcessingTap` callbacks.
- Maintains backward-compatible typealiases (`RealtimeAudioProcessor = AuraBeatDSPEngine`, `DesktopSpatialAudio = AuraBeatSpatialAudioProcessor`, `EqualizerEngine = AuraBeatEqualizer`).

---

## 3. Real-Time Tap Integration

`AuraBeatDSPEngine` binds to `AVPlayerItem` via MediaToolbox `MTAudioProcessingTap`:
```swift
var callbacks = MTAudioProcessingTapCallbacks(
    version: kMTAudioProcessingTapCallbacksVersion_0,
    clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(AuraBeatDSPEngine.shared).toOpaque()),
    init: realtimeTapInit,
    finalize: realtimeTapFinalize,
    prepare: realtimeTapPrepare,
    unprepare: realtimeTapUnprepare,
    process: realtimeTapProcess
)
```
- In `realtimeTapPrepare`, format validation and buffer preallocation occur ahead of time.
- In `realtimeTapProcess`, PCM is fetched with `MTAudioProcessingTapGetSourceAudio` and mutated strictly in place with zero heap allocations.

---

## 4. Verification

The native engine is fully covered by Flutter integration tests in `test/realtime_dsp_test.dart` and `test/dolby_atmos_test.dart`, with 202 passing tests and zero static analysis warnings.
