# AURABEAT — iOS SPATIAL AUDIO IMPLEMENTATION
**Real-Time Native Stereo Widening & Head-Shadow Simulation**
*Source: `AuraBeatSpatialAudioProcessor` in `ios/Runner/AuraBeatAudioManager.swift`*

---

## 1. Algorithmic Fidelity & Desktop 1.8 Parity

The iOS spatial audio subsystem (`AuraBeatSpatialAudioProcessor`) is a direct 1:1 Swift port of `DesktopSpatialAudio` from BitChord Desktop 1.8 (`DesktopAudioProcessors.kt`). The implementation strictly replicates all reference coefficients, equations, buffer geometries, and bypass behaviors.

### 1.1 Mathematical Formulae
For each stereo sample pair $(L, R)$:

$$\text{Mid} = \frac{L + R}{2}$$
$$\text{Side} = \frac{L - R}{2} \times 2.5$$
$$L_{\text{wide}} = \text{Mid} + \text{Side}$$
$$R_{\text{wide}} = \text{Mid} - \text{Side}$$

$$\text{lowpassLeft} \leftarrow \text{lowpassLeft} + 0.3 \times (\text{delayRight}[\text{idx}] - \text{lowpassLeft})$$
$$\text{lowpassRight} \leftarrow \text{lowpassRight} + 0.3 \times (\text{delayLeft}[\text{idx}] - \text{lowpassRight})$$

$$L_{\text{out}} = (L_{\text{wide}} + \text{lowpassLeft} \times 0.2) \times 0.82$$
$$R_{\text{out}} = (R_{\text{wide}} + \text{lowpassRight} \times 0.2) \times 0.82$$

$$\text{delayLeft}[\text{idx}] \leftarrow L, \quad \text{delayRight}[\text{idx}] \leftarrow R$$
$$\text{idx} \leftarrow (\text{idx} + 1) \bmod \text{delayFrames}$$

---

## 2. CoreAudio Buffer Handling

CoreAudio on iOS can present PCM in either **interleaved** format (single buffer containing alternating $L, R$ samples) or **non-interleaved planar** format (separate buffers for $L$ and $R$). `AuraBeatSpatialAudioProcessor` provides dedicated, optimized processing routines for both formats.

### 2.1 Interleaved Stereo Processing
```swift
public func processInterleaved(samples: UnsafeMutablePointer<Float>, count: Int) {
    guard enabled && applies && count >= 2 else { return }
    callbackCount += 1
    let frames = count / 2
    processedFrames += Int64(frames)

    var index = 0
    while index + 1 < count {
        let left = samples[index]
        let right = samples[index + 1]

        let mid = (left + right) * 0.5
        let side = (left - right) * 0.5 * 2.5
        var widenedLeft = mid + side
        var widenedRight = mid - side

        lowpassLeft += 0.3 * (delayRight[delayIndex] - lowpassLeft)
        lowpassRight += 0.3 * (delayLeft[delayIndex] - lowpassRight)
        widenedLeft += lowpassLeft * 0.2
        widenedRight += lowpassRight * 0.2

        delayLeft[delayIndex] = left
        delayRight[delayIndex] = right
        delayIndex = (delayIndex + 1) % delayFrames

        samples[index] = widenedLeft * 0.82
        samples[index + 1] = widenedRight * 0.82
        index += 2
    }
}
```

### 2.2 Planar Stereo Processing
```swift
public func processPlanar(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
    guard enabled && applies && frames > 0 else { return }
    callbackCount += 1
    processedFrames += Int64(frames)

    for i in 0..<frames {
        let l = left[i]
        let r = right[i]

        let mid = (l + r) * 0.5
        let side = (l - r) * 0.5 * 2.5
        var widenedLeft = mid + side
        var widenedRight = mid - side

        lowpassLeft += 0.3 * (delayRight[delayIndex] - lowpassLeft)
        lowpassRight += 0.3 * (delayLeft[delayIndex] - lowpassRight)
        widenedLeft += lowpassLeft * 0.2
        widenedRight += lowpassRight * 0.2

        delayLeft[delayIndex] = l
        delayRight[delayIndex] = r
        delayIndex = (delayIndex + 1) % delayFrames

        left[i] = widenedLeft * 0.82
        right[i] = widenedRight * 0.82
    }
}
```

---

## 3. Strict Safety & Bypass Gates

1. **Mono Streams (`channels == 1`):** Spatial widening is mathematically meaningless on mono and would collapse energy. Mono audio completely bypasses spatial widening, preserving the input bit-for-bit.
2. **Multichannel Streams (`channels > 2`):** Spatial widening applied to discrete multichannel tracks would destroy surround imaging. Multichannel audio is 100% bit-identically bypassed.
3. **Dolby Atmos E-AC-3 JOC Streams:** As mandated by spatial bitstream integrity rules, Atmos tracks bypass `MTAudioProcessingTap` completely.
4. **Buffer Validation:** `AuraBeatAudioFormatValidator` validates `mDataByteSize >= frames * channels * sizeof(Float)` and checks for non-null pointers before passing buffers to the DSP.

---

## 4. Lifecycle & Thread Safety

- **Delay Buffer Sizing:** Delay buffers are allocated once during format negotiation (`prepare`) with size $\text{round}(f_s \times 0.015)$. At 44.1 kHz, `delayFrames` = 662; at 48 kHz, `delayFrames` = 720; at 96 kHz, `delayFrames` = 1440; at 192 kHz, `delayFrames` = 2880.
- **Seeking & Track Switches:** Delay buffers and lowpass filter memory are zeroed out via `reset()` to ensure no transient leakage or pops between tracks.
- **Zero Allocations:** No Swift objects or arrays are instantiated in the render thread callback.
