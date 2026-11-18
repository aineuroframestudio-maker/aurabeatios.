# AuraBeat — BitChord Desktop 1.8 Dolby Atmos Source Map

**Workspace:** `c:\Users\amardeep singh\Downloads\aurabestos-master\aurabestos-master`  
**Reference Source Pack:** BitChord Desktop 1.8 (`BitChord-Desktop-Source-Pack.zip`)  
**Target Platform:** AuraBeat iOS (AVPlayer, CoreAudio, AVAudioSession)  
**Date:** November 16, 2026  

---

## Executive Summary

This document provides a comprehensive audit of all Dolby Atmos, Dolby Digital Plus (E-AC-3), and Joint Object Coding (JOC) source code, classes, methods, constants, algorithms, and architecture in **BitChord Desktop 1.8**. It details the exact mapping to the native iOS audio pipeline in **AuraBeat iOS**, highlighting platform-specific decoding mechanisms, licensing boundaries, and verification criteria.

---

## 1. Complete Source Code Mapping

| # | Feature / Responsibility | Desktop 1.8 Source File | Desktop Class / Function | Desktop Algorithm / Configuration | Dependencies | iOS Equivalent in AuraBeat | Platform Difference / Limitation |
|---|---|---|---|---|---|---|---|
| **1** | **Dolby Capability Probe** | `DesktopCodecs.kt` (lines 14–22) | `DesktopCodecs.supportsDolbyAtmos` | Checks `canDecode("eac3")` via `avcodec_find_decoder_by_name("eac3") != null`. | `libavcodec` (FFmpeg) | `AVAudioSession.isSpatialAudioEnabled` & `AVPlayerItem.allowedAudioSpatializationFormats` | Desktop uses software FFmpeg probe; iOS uses hardware/OS-level Spatial Audio capability reporting. |
| **2** | **Dolby Setting & Preference** | `DesktopApp.kt` (lines 663, 3473, 5477) & `DesktopAddon.kt` (line 217) | `DesktopAddonSettings.dolbyAtmosEnabled` | Persistent boolean key `"dolby_atmos"` (default: `true`). Toggles user preference to request immersive mix. | `DesktopPersistence` | `SharedPreferences` / `AtmosStreamingManager` | Functionally identical setting; controls whether `atmos=auto` is sent to add-on streams. |
| **3** | **Add-on Stream Negotiation** | `DesktopAddon.kt` (lines 335–344) | `DesktopAddonSource.streamParams()` | `val atmosWanted = DesktopCodecs.supportsDolbyAtmos && DesktopAddonSettings.dolbyAtmosEnabled; if (atmosWanted) params.putIfAbsent("atmos", "auto")` | `Ktor` HTTP client | `AtmosStreamingManager` & add-on source query engine | Identical query parameter negotiation (`atmos=auto`). |
| **4** | **Catalogue & Manifest Atmos Hint** | `DesktopAddon.kt` (lines 107, 195, 211) | `ATMOS_HINT` regex & `Row.isDolbyAtmos` | `Regex("""atmos\|dolby\|eac3[_-]?joc\|e-?ac-?3\|ec-?3""", IGNORE_CASE)`. Inspects quality tier, audio modes, container. | Kotlin Standard Library | `HlsAtmosInspector` & `AtmosStreamInfo` | Identical regex patterns and metadata string matching. |
| **5** | **Codec Identification & Normalization** | `DesktopPlayback.kt` (lines 102–140) & `StreamFormat.kt` | `DesktopStreamFormat.codecLabel` | Maps `"eac3"`, `"ec-3"`, `"eac3-joc"` $\rightarrow$ `"E-AC-3"`; `"ac3"` $\rightarrow$ `"AC-3"`. Identifies `isDolbyAtmos`. | None | `AtmosPlayer.swift` (`sourceCodec`) & Dart `AudioPipelineTelemetry` | Identical codec labels and MIME normalization. |
| **6** | **Quality Ranking** | `DesktopModules.kt` (lines 445, 626, 636) | `DesktopModuleSource.qualityRank()` | `DOLBY` tier assigned rank 4 (highest, above `LOSSLESS`=3, `HIGH`=2, `LOW`=1). | None | `QualitySelector` & `AudioQuality.dolbyAtmos` | In AuraBeat, Dolby Atmos ranks at top tier with 48 kHz / 768 kbps metadata. |
| **7** | **Upgrade Guard** | `DesktopAudioEngine.kt` (line 319) | `DesktopAudioEngine.seekBetterCopy()` | If `streamFormat.isDolbyAtmos == true`, prevents replacing stream with stereo lossless upgrade. | Coroutines | AuraBeat Audio Engine playback manager | Preserves immersive Atmos mix even when 24/192 stereo FLAC is available. |
| **8** | **DSP Bypass & Spatial Guard** | `DesktopAudioEngine.kt` (lines 978–982) & `DesktopSpatialGuardTest.kt` | `DesktopAudioEngine.widen()` | `processor.enabled = spatialEnabled && !track.stream.isDolbyAtmos`. Disables stereo widener on Atmos. | `DesktopSpatialAudio` | `AuraBeatAudioManager.swift` (`isAtmosTrack`) & `RealtimeAudioProcessor` | Complete bypass of `MTAudioProcessingTap` and stereo widening to prevent spatial bed destruction. |
| **9** | **Audio Playback / Decoding Sink** | `DesktopAudioDecoder.kt` & `PrecisionAudioSink.kt` | `DesktopAudioDecoder` (Desktop) / `PrecisionAudioSink` (Android) | Desktop: FFmpeg `eac3` decoder decodes bitstream. Android: `PrecisionAudioSink` routes `audio/eac3-joc` to AudioTrack. | `FFmpeg` (Desktop) / `Media3` (Android) | `AtmosPlayer.swift` (AVPlayer + CoreAudio Spatial Audio renderer) | **Critical Platform Distinction:** Desktop decodes via software FFmpeg; iOS delegates to Apple's licensed CoreAudio Dolby Audio Decoder. |
| **10** | **HLS Audio Rendition Selection** | `DesktopPlayback.kt` (line 78) & `DesktopAddon.kt` (line 167) | `DesktopStream.transport` (`hls` / `dash`) | Directs player to parse HLS manifest or DASH manifest for E-AC-3 JOC renditions. | None | `AVPlayerItem` & `HlsAtmosInspector.dart` | Apple AVPlayer natively selects and renders the highest-quality multichannel HLS rendition. |
| **11** | **Now Playing UI & Badge** | `PlayerControls.kt` (lines 1564–1567) | `PlayerControls` `LosslessLabel` | Renders animated "Dolby Atmos" badge with `ic_dolby_atmos` icon when `nerdStats.isDolbyAtmos == true`. | Jetpack Compose | `AtmosBadge.dart` & `AtmosDiagnosticScreen.dart` | Equivalent Flutter UI component displaying verified Dolby status. |
| **12** | **Technical Diagnostics** | `NerdStats.kt` (lines 106, 188, 219) | `NerdStats` | Reports `isDolbyAtmos`, sample rate (48 kHz), channels, codec name. | None | `AtmosPlayer.swift` (`getStatus()`) & `AudioPipelineTelemetry.dart` | iOS exposes extended Apple-specific spatial routing telemetry. |

---

## 2. Platform Architecture & Licensing Distinctions

### Desktop (BitChord 1.8 JVM)
- **Decoding Mechanism:** Open-source `libavcodec` (via JavaCPP Bytedeco presets) decodes E-AC-3 streams in software.
- **Spatial Object Rendering:** Software FFmpeg downmixes or routes discrete 5.1 channels into a stereo or multichannel PCM stream. It does not contain Apple's proprietary binaural Head-Related Transfer Function (HRTF) renderer.
- **Licensing:** FFmpeg LGPL/GPL builds handle E-AC-3 decoding without hardware cryptographic attestations.

### iOS (AuraBeat Native)
- **Decoding Mechanism:** Native Apple CoreAudio and MediaToolbox (`AVPlayer` / `AVAudioSession`).
- **Spatial Object Rendering:** Apple's licensed Dolby Audio Decoder and Spatial Audio engine (`.monoStereoAndMultichannel`) dynamically render JOC metadata and height/bed channels into binaural spatial audio for AirPods and compatible hardware speakers.
- **Licensing & Boundary:** Third-party apps on iOS cannot inject custom software decoders that hijack the protected Apple Atmos binaural pipeline without losing system spatialization. Therefore, AuraBeat delegates playback of encoded E-AC-3 JOC streams directly to `AVPlayer` with `isTapActive = false` (bypassing `MTAudioProcessingTap`), allowing Apple's licensed hardware/OS framework to render genuine Dolby Atmos.

---

## 3. Strict Verification Criteria

To maintain integrity and prevent misleading representations, AuraBeat enforces 7 distinct diagnostic states:

1. `manifestInferred`: HLS master playlist declares `CODECS="ec-3"` with JOC signaling.
2. `codecDetected`: Stream header or mime type confirmed as `audio/eac3` or `audio/eac3-joc`.
3. `bitstreamVerified`: Binary syncframe ($0\text{x0B77}$) and E-AC-3 bitstream headers validated by `Eac3BitstreamValidator`.
4. `jocMetadataVerified`: Specific JOC object-based metadata found inside the E-AC-3 container.
5. `systemSpatialPlaybackAvailable`: Current output route (`AVAudioSession.isSpatialAudioEnabled`) confirms spatial playback capability.
6. `appDspBypassed`: AuraBeat's internal DSP (`MTAudioProcessingTap`, widening, EQ) is strictly disengaged.
7. `endToEndAtmosRenderingVerified`: All upstream requirements met, player is actively decoding, and spatialization permission is permitted.

---
*Mapping audit complete. Proceeding to Phase 2 implementation.*
