# AURABEAT — BITCHORD DESKTOP 1.8 DSP ANALYSIS
**Comprehensive Algorithmic, Mathematical, and Structural Source Audit**
*Reference: BitChord Desktop 1.8 Source Package (`BitChord-1.8/`)*

---

## 1. Overview and Architecture

BitChord Desktop 1.8 implements an in-process, high-fidelity digital signal processing (DSP) pipeline operating on 32-bit floating point PCM audio. The pipeline is designed around three core principles:
1. **Topology-Preserving Filtering:** Filter mathematics that remain stable and true to analog prototypes across the entire audible range (10 Hz to 20 kHz), avoiding high-frequency cramping and low-frequency truncation.
2. **Zipper-Free Parameter Gliding:** Continuous geometric and linear sub-block interpolation preventing clicks, pops, and step artifacts during rapid UI interaction.
3. **Strict Natural Headroom Protection:** Mathematical make-up attenuation derived from real-time response scans rather than scalar approximations.

---

## 2. DesktopSpatialAudio (Stereo Widener)

### 2.1 File Location
- Source: `desktopApp/src/main/kotlin/com/music/bitchord/desktop/DesktopAudioProcessors.kt`

### 2.2 Algorithm and Constants
Stereo widening uses Mid/Side expansion combined with opposite-ear head-shadow simulation and crossfeed:

$$\text{Mid} = \frac{L + R}{2}$$
$$\text{Side} = \frac{L - R}{2} \times \text{widthGain}$$
$$L_{\text{wide}} = \text{Mid} + \text{Side}$$
$$R_{\text{wide}} = \text{Mid} - \text{Side}$$

Crossfeed is simulated via a single-pole lowpass filter processing the opposite channel's 15ms delayed buffer:

$$\text{lowpassL} \leftarrow \text{lowpassL} + \text{lowpassCoeff} \times (D_R[\text{idx}] - \text{lowpassL})$$
$$\text{lowpassR} \leftarrow \text{lowpassR} + \text{lowpassCoeff} \times (D_L[\text{idx}] - \text{lowpassR})$$
$$L_{\text{out}} = (L_{\text{wide}} + \text{lowpassL} \times \text{crossfeedGain}) \times \text{outputGain}$$
$$R_{\text{out}} = (R_{\text{wide}} + \text{lowpassR} \times \text{crossfeedGain}) \times \text{outputGain}$$

$$D_L[\text{idx}] \leftarrow L, \quad D_R[\text{idx}] \leftarrow R, \quad \text{idx} \leftarrow (\text{idx} + 1) \bmod \text{delayFrames}$$

### 2.3 Reference Constants
| Parameter | Value | Meaning |
| :--- | :--- | :--- |
| `delayMs` | `15.0` | Opposite-ear head-shadow delay time |
| `widthGain` | `2.5` | Mid/Side expansion multiplier |
| `outputGain` | `0.82` | -1.72 dB anti-clipping make-up attenuation |
| `crossfeedGain` | `0.2` | Opposite channel crossfeed intensity |
| `lowpassCoeff` | `0.3` | Single-pole lowpass filter smoothing factor |

### 2.4 Channel Applicability Rules
- Applies strictly when `channels == 2`.
- Mono (`channels == 1`) and Multichannel (`channels > 2`) streams are **bit-identically bypassed**.

---

## 3. DesktopEqualizer (Cytomic State-Variable Filter)

### 3.1 File Locations
- Core SVF: `desktopApp/src/main/kotlin/com/music/bitchord/desktop/DesktopEqualizer.kt`
- Layout & Math: `shared/src/commonMain/kotlin/com/music/bitchord/playback/EqualizerCurve.kt`
- Presets: `shared/src/commonMain/kotlin/com/music/bitchord/playback/EqualizerPreset.kt`

### 3.2 10-Slot Cascade Layout (`EqLayout`)
The equalizer cascade maintains 10 continuous filter slots across both manual and dynamic modes:

| Slot | Kind | Frequency | Bandwidth / Q | Purpose |
| :---: | :---: | :---: | :---: | :--- |
| **0** | `LOW_SHELF` | 60 Hz | Q = 1.0 | Manual Slider 1 (Bass Shelf) |
| **1** | `BELL` | 150 Hz | Q = 1.0 | Manual Slider 2 (Bass Punch) |
| **2** | `BELL` | 400 Hz | Q = 1.0 | Manual Slider 3 (Lower Mid) |
| **3** | `BELL` | 1000 Hz | Q = 1.0 | Manual Slider 4 (Midrange) |
| **4** | `BELL` | 2500 Hz | Q = 1.0 | Manual Slider 5 (Upper Mid) |
| **5** | `BELL` | 6000 Hz | Q = 1.0 | Manual Slider 6 (Presence) |
| **6** | `HIGH_SHELF`| 14000 Hz| Q = 1.0 | Manual Slider 7 (Air Shelf) |
| **7** | `LOW_SHELF` | 250 Hz | Focused: 0.9 / Broad: 0.5 | Tone Pad Tilt Low |
| **8** | `BELL` | 1000 Hz| Focused: 2.2 / Broad: 0.7 | Tone Pad Contour Mid |
| **9** | `HIGH_SHELF`| 4000 Hz| Focused: 0.9 / Broad: 0.5 | Tone Pad Tilt High |

### 3.3 Cytomic SVF Trapezoidal Integration Equations
For each active slot:
$$A = 10^{\frac{\text{gainDb}}{40}}$$
$$g = \tan\left(\frac{\pi \times \text{clamp}(f_0, 10, 0.45 f_s)}{f_s}\right)$$

Depending on filter kind:
- **Bell:** $g = \text{base}$, $k = \frac{1}{q A}$, $\text{mixInput} = 1$, $\text{mixBand} = k(A^2 - 1)$, $\text{mixLow} = 0$
- **Low Shelf:** $g = \frac{\text{base}}{\sqrt{A}}$, $k = \frac{1}{q}$, $\text{mixInput} = 1$, $\text{mixBand} = k(A - 1)$, $\text{mixLow} = A^2 - 1$
- **High Shelf:** $g = \text{base}\sqrt{A}$, $k = \frac{1}{q}$, $\text{mixInput} = A^2$, $\text{mixBand} = k(1 - A)A$, $\text{mixLow} = 1 - A^2$

Integrator denominators:
$$d = \frac{1}{1 + g(g + k)}, \quad a_1 = d, \quad a_2 = gd, \quad a_3 = g^2 d$$

Per-sample filter execution:
$$v_3 = \text{input} - \text{ic}_2$$
$$v_1 = a_1 \text{ic}_1 + a_2 v_3$$
$$v_2 = \text{ic}_2 + a_2 \text{ic}_1 + a_3 v_3$$
$$\text{ic}_1 \leftarrow 2 v_1 - \text{ic}_1, \quad \text{ic}_2 \leftarrow 2 v_2 - \text{ic}_2$$
$$\text{output} = \text{mixInput} \cdot \text{input} + \text{mixBand} \cdot v_1 + \text{mixLow} \cdot v_2$$

### 3.4 96-Point Logarithmic Response Preamp Scan (`preampFor`)
Rather than using a single-band scalar, Desktop 1.8 scans 96 log-spaced points from 20 Hz to 20 kHz:
$$f_i = 20 \times 1000^{\frac{i}{95}} \quad (i = 0 \dots 95)$$
$$\text{SumGain}(f_i) = \sum_{s=0}^{9} \text{sectionGainDb}(s, f_i)$$
$$\text{preampDb} = -\max_{i} \left(\max(0, \text{SumGain}(f_i))\right)$$

### 3.5 Parameter Gliding and Denormal Flushing
- `GLIDE_FRAMES` = 64 frames per sub-block (~1.45 ms at 44.1 kHz).
- `GLIDE_RATE` = 0.08 per sub-block (~18 ms time constant).
- Decibel gains and balance glide linearly; Q values glide geometrically.
- Denormal floor: Integrator states below $10^{-12}$ are flushed to zero to prevent CPU penalties.

### 3.6 Far-Channel Balance Attenuation
To preserve volume linearity, stereo balance attenuates the opposite channel rather than boosting the near channel:
$$\text{Gain}_L = \text{preamp} \times \min(1.0, 1.0 - \text{balance})$$
$$\text{Gain}_R = \text{preamp} \times \min(1.0, 1.0 + \text{balance})$$

---

## 4. Master Processing Order

The reference audio engine strictly executes DSP in the following staged sequence:

```
Decoded Input PCM
       │
       ▼
[Stage 1: DesktopSpatialAudio] (Mid/Side widening & crossfeed on 2.0 stereo)
       │
       ▼
[Stage 2: DesktopEqualizer] (10-slot Cytomic SVF + 96-pt Preamp + Balance)
       │
       ▼
[Stage 3: Silence Energy Tracking] (RMS calculation < 0.001 / -60 dBFS)
       │
       ▼
[Stage 4: Playback Speed Adjustment] (Pitch-preserving stretch)
       │
       ▼
Sink Audio Output
```
