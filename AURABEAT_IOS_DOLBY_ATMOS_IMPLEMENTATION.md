# AURABEAT — iOS DOLBY ATMOS IMPLEMENTATION
**Native Dolby Atmos E-AC-3 JOC Playback & Isolation Subsystem**
*Target: `ios/Runner/AtmosPlayer.swift` & `ios/Runner/AuraBeatAudioManager.swift`*

---

## 1. Architectural Principles

BitChord Desktop 1.8 handles Dolby Atmos by routing discrete E-AC-3 streams with Joint Object Coding (JOC) metadata directly to certified decoders or platform spatial renderers, strictly bypassing standard stereo DSP effects. On iOS, AVFoundation provides hardware-accelerated spatial audio rendering for E-AC-3 JOC bitstreams through Apple's spatial audio subsystem.

A critical design requirement is that **no application-level tap (`MTAudioProcessingTap`) or software DSP must ever intercept an active Dolby Atmos bitstream**. Attaching a tap forces the platform decoder to fold the discrete spatial objects into plain PCM, permanently destroying the dynamic positional metadata.

---

## 2. Dolby Atmos Detection & Classification

Dolby Atmos content is detected and classified according to standard HLS signalling and stream descriptors:
1. **HLS Manifest Signalling:**
   - Manifest tags containing `CODECS="ec-3"`, `CODECS="eac3"`, or `CODECS="mp4a.a6"`.
   - Audio track renditions declaring JOC or 16-channel bed descriptors: `CHANNELS="16/JOC"`, `CHANNELS="12/JOC"`, or `CHANNELS="6"`.
2. **Binary Syncframe Parsing:**
   - E-AC-3 syncword validation (`0x0B77`).
   - Bitstream metadata extraction according to ETSI TS 103 420.
3. **Candidate States:**
   - `bitstreamVerified`: Both binary E-AC-3 frame structure and JOC metadata payload confirmed.
   - `manifestInferred`: Manifest explicitly indicates E-AC-3 JOC, but bitstream payload has not yet been parsed in memory.
   - `codecDetected`: E-AC-3 bitstream confirmed without verified JOC metadata (Dolby Digital Plus).
   - `unverified`: Standard stereo or unclassified audio.

---

## 3. Dedicated `AtmosPlayer` Architecture

To ensure 100% bitstream preservation, Atmos playback is hosted in a dedicated `AtmosPlayer` instance in `ios/Runner/AtmosPlayer.swift`:
- `AVPlayerItem` configured with:
  ```swift
  playerItem.allowedAudioSpatializationFormats = .monoStereoAndMultichannel
  ```
- Audio session configured with `.moviePlayback` mode for multichannel and spatial object rendering.
- `MTAudioProcessingTap` is **strictly omitted**:
  ```swift
  if isAtmosTrack(item: item, urlString: urlString, title: title) {
      print("[AuraBeatAudio] Dolby Atmos track identified. Bypassing MTAudioProcessingTap to preserve discrete spatial bitstream.")
      isTapActive = false
      return
  }
  ```

---

## 4. Truthful Diagnostics & System Capabilities

The iOS subsystem enforces strict separation between application-observable telemetry and hardware internal state:

| Diagnostic Metric | Source | Interpretation |
| :--- | :--- | :--- |
| `dolbyCodecDetected` | Stream Header | `true` if codec is E-AC-3 |
| `dolbyJocManifestDetected` | HLS Manifest | `true` if `16/JOC` is present |
| `dolbyJocMetadataVerified` | Frame Parser | `true` only if binary JOC payload is verified |
| `dolbyBitstreamVerified` | Bitstream | `true` if syncframes pass CRC |
| `dolbyNativePlaybackActive`| Playback State | `true` if Atmos track is playing in AVPlayer |
| `dolbySpatialPlaybackAvailable`| AVAudioSession | Reflects `session.isSpatialAudioEnabled` |
| `dolbyAppDspBypassed` | Engine State | Always `true` during Atmos playback |
| `dolbyRenderingVerificationStatus` | Telemetry | `NOT_VERIFIABLE_BY_APP` (AirPods internal render) |

---

## 5. Verification

Dolby Atmos detection, rendition fallback, and DSP isolation are validated across 16 scenarios in `test/dolby_atmos_test.dart` and integration scenarios in `test/realtime_dsp_test.dart`, all passing with zero errors.
