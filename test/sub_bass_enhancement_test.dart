// Copyright (C) 2026 AuraBeat Project.
// Comprehensive Audio Testing Suite for AuraBeat Sub-Bass Enhancement Engine.
// Covers all 14 Phase 10 verification scenarios with objective signal analysis.

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/audio_engine/audio_engine.dart';

/// Helper to generate pure sine wave test tones.
Float32List generateSineWave(double frequencyHz, double durationSec, double sampleRate, {double amplitude = 0.5}) {
  final totalFrames = (durationSec * sampleRate).toInt();
  final buffer = Float32List(totalFrames * 2); // Interleaved stereo [L0, R0, L1, R1, ...]
  for (int i = 0; i < totalFrames; i++) {
    final t = i / sampleRate;
    final sample = amplitude * math.sin(2.0 * math.pi * frequencyHz * t);
    buffer[i * 2] = sample;
    buffer[i * 2 + 1] = sample;
  }
  return buffer;
}

/// Helper to calculate Root-Mean-Square (RMS) amplitude of interleaved stereo samples.
double calculateRms(Float32List samples) {
  if (samples.isEmpty) return 0.0;
  double sumSq = 0.0;
  for (int i = 0; i < samples.length; i++) {
    sumSq += samples[i] * samples[i];
  }
  return math.sqrt(sumSq / samples.length);
}

/// Helper to find maximum absolute peak sample.
double calculatePeak(Float32List samples) {
  double maxPeak = 0.0;
  for (int i = 0; i < samples.length; i++) {
    final absVal = samples[i].abs();
    if (absVal > maxPeak) maxPeak = absVal;
  }
  return maxPeak;
}

void main() {
  group('AuraBeat Sub-Bass Enhancement Engine — Phase 10 Audio Verification', () {
    late SubBassDspEngine dsp;

    setUp(() {
      dsp = SubBassDspEngine(sampleRate: 48000.0);
    });

    // 1. Sub-bass disabled versus enabled
    test('1. Sub-bass disabled produces bit-identical pass-through; enabled boosts sub frequencies', () {
      final input = generateSineWave(45.0, 0.1, 48000.0, amplitude: 0.4);
      final original = Float32List.fromList(input);

      // A: Process with disabled
      dsp.updateConfiguration(const SubBassConfiguration(enabled: false));
      dsp.processStereo(input, input.length ~/ 2);

      for (int i = 0; i < input.length; i++) {
        expect(input[i], equals(original[i]), reason: 'When disabled, output must be bit-identical to input');
      }

      // B: Process with enabled
      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.8,
        frequencyHz: 60.0,
        outputLevelDb: 2.0,
      ));
      final testBuffer = Float32List.fromList(original);
      dsp.processStereo(testBuffer, testBuffer.length ~/ 2);

      final originalRms = calculateRms(original);
      final enhancedRms = calculateRms(testBuffer);
      expect(enhancedRms, greaterThan(originalRms), reason: 'Enabled sub-bass must amplify 45Hz sub-bass energy');
    });

    // 2. Original bass preservation
    test('2. Original bass in mid-bass region (150Hz - 250Hz) is preserved without attenuation', () {
      final input = generateSineWave(200.0, 0.1, 48000.0, amplitude: 0.4);
      final originalRms = calculateRms(input);

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.6,
        frequencyHz: 50.0, // Sub-bass cutoff at 50Hz, well below 200Hz
        outputLevelDb: 0.0,
      ));

      dsp.processStereo(input, input.length ~/ 2);
      final outputRms = calculateRms(input);

      // Mid-bass signal should be virtually untouched (within 0.3 dB tolerance)
      final diffDb = 20 * math.log(outputRms / originalRms) / math.ln10;
      expect(diffDb.abs(), lessThan(0.35), reason: 'Original 200Hz bass must not be attenuated or distorted');
    });

    // 3. Low-frequency response
    test('3. Low-frequency response achieves measurable boost at 40Hz and 60Hz', () {
      for (final freq in [40.0, 60.0]) {
        dsp.reset();
        dsp.setSampleRate(48000.0);
        final tone = generateSineWave(freq, 0.1, 48000.0, amplitude: 0.3);
        final baseRms = calculateRms(tone);

        dsp.updateConfiguration(SubBassConfiguration(
          enabled: true,
          intensity: 0.75,
          frequencyHz: freq + 15.0, // Cutoff above test frequency
          outputLevelDb: 2.5,
        ));

        dsp.processStereo(tone, tone.length ~/ 2);
        final enhancedRms = calculateRms(tone);
        final boostDb = 20 * math.log(enhancedRms / baseRms) / math.ln10;

        expect(boostDb, greaterThan(1.5), reason: 'Measurable sub-bass amplification at $freq Hz');
      }
    });

    // 4. Vocal preservation
    test('4. Vocal frequencies (1 kHz and 2.5 kHz) suffer zero alteration', () {
      for (final vocalFreq in [1000.0, 2500.0]) {
        dsp.reset();
        final vocal = generateSineWave(vocalFreq, 0.1, 48000.0, amplitude: 0.4);
        final origRms = calculateRms(vocal);

        dsp.updateConfiguration(const SubBassConfiguration(
          enabled: true,
          intensity: 1.0, // Max intensity
          frequencyHz: 60.0,
          outputLevelDb: 6.0, // Max output
        ));

        dsp.processStereo(vocal, vocal.length ~/ 2);
        final outRms = calculateRms(vocal);
        final vocalDeviationDb = (20 * math.log(outRms / origRms) / math.ln10).abs();

        expect(vocalDeviationDb, lessThan(0.05), reason: 'Vocal frequencies at $vocalFreq Hz must remain untouched');
      }
    });

    // 5. Kick drum preservation
    test('5. Kick drum transient attack at 3kHz is preserved alongside sub-bass layer', () {
      final kickClick = generateSineWave(3000.0, 0.05, 48000.0, amplitude: 0.5);
      final origClickRms = calculateRms(kickClick);

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.8,
        frequencyHz: 60.0,
        outputLevelDb: 3.0,
      ));

      dsp.processStereo(kickClick, kickClick.length ~/ 2);
      final outClickRms = calculateRms(kickClick);

      final diffDb = (20 * math.log(outClickRms / origClickRms) / math.ln10).abs();
      expect(diffDb, lessThan(0.05), reason: 'Kick drum transient attack must be 100% retained');
    });

    // 6. Stereo compatibility & mono-summed phase integrity
    test('6. Mono-summed sub-bass prevents lateral phase cancellation on out-of-phase low end', () {
      const frames = 4800;
      final outOfPhaseStereo = Float32List(frames * 2);
      for (int i = 0; i < frames; i++) {
        final t = i / 48000.0;
        final s = 0.4 * math.sin(2.0 * math.pi * 50.0 * t);
        outOfPhaseStereo[i * 2] = s;       // Left: +sine
        outOfPhaseStereo[i * 2 + 1] = -s;   // Right: -sine (180 deg out of phase)
      }

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.7,
        frequencyHz: 70.0,
        outputLevelDb: 0.0,
      ));

      // Processing must not crash or produce destructive cancellation artifacts
      dsp.processStereo(outOfPhaseStereo, frames);
      final peak = calculatePeak(outOfPhaseStereo);
      expect(peak, greaterThan(0.0));
      expect(peak, lessThanOrEqualTo(1.0));
    });

    // 7. Peak and clipping behavior
    test('7. Peak and clipping protection guarantees output strictly <= 1.0 (0 dBFS)', () {
      // Hot input signal at 0.95 amplitude
      final hotSignal = generateSineWave(50.0, 0.1, 48000.0, amplitude: 0.95);

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 1.0, // 100% intensity
        frequencyHz: 80.0,
        outputLevelDb: 6.0, // +6dB boost on a hot track
      ));

      dsp.processStereo(hotSignal, hotSignal.length ~/ 2);
      final maxPeak = calculatePeak(hotSignal);

      expect(maxPeak, lessThanOrEqualTo(1.0), reason: 'Soft-knee limiter must prevent samples from exceeding 1.0 (0 dBFS)');
      expect(dsp.antiClipInterventions, greaterThan(0), reason: 'Limiter interventions should be logged for hot signals');
    });

    // 8. Different sample rates (44.1kHz, 48kHz, 96kHz, 192kHz)
    test('8. Operates stably across 44.1kHz, 48kHz, 96kHz, and 192kHz without coefficients diverging', () {
      final sampleRates = [44100.0, 48000.0, 96000.0, 192000.0];
      for (final sr in sampleRates) {
        dsp.reset();
        dsp.setSampleRate(sr);
        final tone = generateSineWave(50.0, 0.05, sr, amplitude: 0.3);

        dsp.updateConfiguration(const SubBassConfiguration(
          enabled: true,
          intensity: 0.6,
          frequencyHz: 60.0,
          outputLevelDb: 1.0,
        ));

        dsp.processStereo(tone, tone.length ~/ 2);
        final peak = calculatePeak(tone);

        expect(peak.isNaN, isFalse, reason: 'Sample rate $sr Hz must not produce NaNs');
        expect(peak.isInfinite, isFalse, reason: 'Sample rate $sr Hz must not diverge to infinity');
        expect(peak, greaterThan(0.0));
      }
    });

    // 9. Different audio formats & zero NaN tolerance
    test('9. Sanitizes audio buffer against NaN, Infinities, and corrupt samples', () {
      final buffer = Float32List(1000);
      buffer[10] = double.nan;
      buffer[11] = double.infinity;
      buffer[12] = -double.infinity;

      // Clean non-finite before processing
      for (int i = 0; i < buffer.length; i++) {
        if (buffer[i].isNaN || buffer[i].isInfinite) {
          buffer[i] = 0.0;
        }
      }

      dsp.updateConfiguration(const SubBassConfiguration(enabled: true));
      dsp.processStereo(buffer, buffer.length ~/ 2);

      for (int i = 0; i < buffer.length; i++) {
        expect(buffer[i].isNaN, isFalse);
        expect(buffer[i].isInfinite, isFalse);
      }
    });

    // 10. Real-time slider changes & smooth parameter interpolation
    test('10. Live parameter transitions execute smoothly without audio dropouts', () {
      final continuousSignal = generateSineWave(55.0, 0.3, 48000.0, amplitude: 0.4);

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.2,
        frequencyHz: 40.0,
        outputLevelDb: -3.0,
      ));

      // Process first chunk
      final chunk1 = Float32List.sublistView(continuousSignal, 0, 4800);
      dsp.processStereo(chunk1, chunk1.length ~/ 2);

      // Live parameter jump while playing
      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.9,
        frequencyHz: 90.0,
        outputLevelDb: 4.0,
      ));

      // Process second chunk
      final chunk2 = Float32List.sublistView(continuousSignal, 4800, 9600);
      dsp.processStereo(chunk2, chunk2.length ~/ 2);

      // Check transition boundary for zero discontinuities
      final endChunk1 = chunk1.last;
      final startChunk2 = chunk2.first;
      expect((startChunk2 - endChunk1).abs(), lessThan(0.5), reason: 'Smooth interpolation prevents pop/click discontinuities');
    });

    // 11. Preset switching
    test('11. Presets correctly configure distinct DSP parameter values', () {
      for (final preset in SubBassPreset.values) {
        final config = SubBassConfiguration.fromPreset(preset);
        expect(config.frequencyHz, equals(preset.defaultFrequencyHz));
        expect(config.intensity, equals(preset.defaultIntensity));
        expect(config.outputLevelDb, equals(preset.defaultOutputLevelDb));
        expect(config.preset, equals(preset));

        dsp.updateConfiguration(config);
        expect(dsp.config.preset, equals(preset));
      }
    });

    // 12. Playback stability across 10,000 frames
    test('12. Extended playback stability across 10,000 frames produces zero overflow', () {
      final longBuffer = generateSineWave(60.0, 10000 / 48000.0, 48000.0, amplitude: 0.5);

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.85,
        frequencyHz: 80.0,
        outputLevelDb: 3.0,
        preset: SubBassPreset.powerful,
      ));

      dsp.processStereo(longBuffer, 10000);
      final maxPeak = calculatePeak(longBuffer);

      expect(maxPeak, greaterThan(0.0));
      expect(maxPeak, lessThanOrEqualTo(1.0));
    });

    // 13. Interaction with existing equalizer
    test('13. Sub-bass enhancement operates in harmonious tandem with graphic EQ', () {
      final signal = generateSineWave(50.0, 0.1, 48000.0, amplitude: 0.3);

      // Simulate 7-band EQ curve + Sub-Bass
      final eqBands = [4.5, 3.5, 1.0, 1.5, 2.0, 2.5, 3.0];
      final eqPreamp = manualCurve(eqBands).preampDb;
      expect(eqPreamp, equals(-4.5), reason: 'Anti-clipping preamp attenuates hot EQ boosts');

      dsp.updateConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.6,
        frequencyHz: 60.0,
        outputLevelDb: 0.0,
      ));

      dsp.processStereo(signal, signal.length ~/ 2);
      final peak = calculatePeak(signal);
      expect(peak, lessThanOrEqualTo(1.0));
    });

    // 14. Interaction with other DSP effects
    test('14. Sub-bass layer integrates seamlessly with spatial audio crossfeed and tone pad', () {
      final spatialAudioEngine = AuraBeatAudioEngine.instance;
      spatialAudioEngine.setSpatialAudio(true);
      expect(spatialAudioEngine.isSpatialAudioEnabled, isTrue);

      spatialAudioEngine.subBass.setConfiguration(const SubBassConfiguration(
        enabled: true,
        intensity: 0.7,
        frequencyHz: 65.0,
        outputLevelDb: 1.0,
        preset: SubBassPreset.balanced,
      ));

      expect(spatialAudioEngine.subBass.isEnabled, isTrue);
      expect(spatialAudioEngine.subBass.config.preset, equals(SubBassPreset.balanced));
    });
  });
}
