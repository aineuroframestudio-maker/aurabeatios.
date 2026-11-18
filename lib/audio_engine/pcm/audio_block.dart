// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord audio engine (Apache License 2.0).

import 'dart:math' as math;
import 'dart:typed_data';

/// Reusable memory block holding interleaved Float32 PCM samples.
///
/// All samples are stored in [samples] as normalized IEEE 754 32-bit floats.
/// The nominal audio amplitude range is `[-1.0, +1.0]`, though intermediate DSP
/// operations may use values outside this range (headroom) before final clamping or dithering.
///
/// Designed to be allocated once per processor/sink lifecycle and reused across
/// audio callbacks, avoiding GC pressure and heap allocations in steady-state playback.
class AudioBlock {
  static const int defaultChannels = 2;
  static const int defaultCapacityFrames = 4096;

  final int channelCount;
  final int capacityFrames;

  /// Pre-allocated contiguous sample array sized for capacityFrames * channelCount.
  final Float32List samples;

  /// Number of valid audio frames currently present in this block.
  int _frameCount = 0;

  AudioBlock({
    this.channelCount = defaultChannels,
    this.capacityFrames = defaultCapacityFrames,
  })  : assert(channelCount > 0, 'channelCount must be positive: $channelCount'),
        assert(capacityFrames > 0, 'capacityFrames must be positive: $capacityFrames'),
        samples = Float32List(capacityFrames * channelCount);

  /// Number of valid audio frames currently present in this block.
  int get frameCount => _frameCount;

  /// Total number of valid samples currently in this block (frameCount * channelCount).
  int get sampleCount => _frameCount * channelCount;

  /// Resets the active frame count for a new processing cycle without reallocating memory.
  void reset([int frames = 0]) {
    assert(frames >= 0 && frames <= capacityFrames, 'frames ($frames) out of range 0..$capacityFrames');
    _frameCount = frames;
  }

  /// Updates frameCount after writing samples directly into [samples].
  void setFrameCount(int frames) => reset(frames);

  /// Clears all samples in the active region to 0.0 (silence) and resets frame count to 0.
  void clear() {
    if (sampleCount > 0) {
      samples.fillRange(0, sampleCount, 0.0);
    }
    _frameCount = 0;
  }

  /// Copies a range of frames from [source] into this block.
  void copyFrom(
    AudioBlock source, {
    int sourceStartFrame = 0,
    int destStartFrame = 0,
    int? frames,
  }) {
    final frameCountToCopy = frames ?? (source.frameCount - sourceStartFrame);
    assert(source.channelCount == channelCount, 'Channel count mismatch');
    assert(sourceStartFrame >= 0 && sourceStartFrame + frameCountToCopy <= source.frameCount, 'Source range out of bounds');
    assert(destStartFrame >= 0 && destStartFrame + frameCountToCopy <= capacityFrames, 'Dest range out of bounds');

    if (frameCountToCopy <= 0) return;

    final srcOffset = sourceStartFrame * channelCount;
    final dstOffset = destStartFrame * channelCount;
    final count = frameCountToCopy * channelCount;

    samples.setRange(dstOffset, dstOffset + count, source.samples, srcOffset);
    _frameCount = math.max(_frameCount, destStartFrame + frameCountToCopy);
  }

  /// Computes the maximum absolute peak amplitude across all valid samples.
  double computePeak() {
    if (sampleCount <= 0) return 0.0;
    double maxVal = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final val = samples[i].abs();
      if (val > maxVal) maxVal = val;
    }
    return maxVal;
  }

  /// Computes the Root Mean Square (RMS) level across all valid samples.
  double computeRms() {
    if (sampleCount <= 0) return 0.0;
    double sumSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final s = samples[i];
      sumSquares += s * s;
    }
    return math.sqrt(sumSquares / sampleCount);
  }

  /// Determines if any sample exceeds full scale (1.0 or -1.0).
  bool isClipping([double threshold = 1.0]) {
    return computePeak() > threshold;
  }

  /// Headroom in decibels below full scale (0 dBFS). Negative value indicates clipping.
  double computeHeadroomDb() {
    final peak = computePeak();
    if (peak <= 0.0) return 96.0; // effectively noise floor
    return -20.0 * (math.log(peak) / math.ln10);
  }

  /// Applies a scalar gain to all samples in the active region.
  void applyGain(double gain) {
    if (gain == 1.0) return;
    for (int i = 0; i < sampleCount; i++) {
      samples[i] = samples[i] * gain;
    }
  }
}
