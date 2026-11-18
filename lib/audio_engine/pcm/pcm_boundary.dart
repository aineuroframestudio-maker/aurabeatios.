// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord audio engine (Apache License 2.0).

import 'dart:math' as math;
import 'dart:typed_data';
import 'audio_block.dart';
import 'pcm_encoding.dart';

/// Boundary layer converting raw PCM byte buffers to and from canonical [AudioBlock] Float32 representations.
///
/// Assumes Little-Endian byte order matching Android AudioTrack, iOS CoreAudio / AVFoundation, and WebAudio standards.
///
/// Normalization mappings:
/// - 16-bit signed integer: normalized by 1 / 32768.0 (range: -1.0 .. +0.9999695)
/// - 24-bit packed integer: normalized by 1 / 8388608.0 (range: -1.0 .. +0.99999988)
/// - 32-bit integer: normalized by 1 / 2147483648.0 (range: -1.0 .. +1.0)
/// - 32-bit float: direct mapping with sanitization for NaN / Infinity
class PcmBoundary {
  static const double _inv16 = 1.0 / 32768.0;
  static const double _inv24 = 1.0 / 8388608.0;
  static const double _inv32 = 1.0 / 2147483648.0;

  /// Decodes raw PCM bytes from [inputBytes] into [destinationBlock].
  ///
  /// Returns the number of full audio frames decoded into [destinationBlock].
  static int decode({
    required Uint8List inputBytes,
    required PcmEncoding encoding,
    required AudioBlock destinationBlock,
    int? maxFrames,
  }) {
    final channelCount = destinationBlock.channelCount;
    final bytesPerFrame = encoding.bytesPerFrame(channelCount);
    if (bytesPerFrame <= 0) {
      destinationBlock.reset(0);
      return 0;
    }

    final availableFrames = inputBytes.length ~/ bytesPerFrame;
    final requestedLimit = maxFrames ?? destinationBlock.capacityFrames;
    final framesToRead = math.min(math.min(availableFrames, requestedLimit), destinationBlock.capacityFrames);

    if (framesToRead <= 0) {
      destinationBlock.reset(0);
      return 0;
    }

    final byteData = ByteData.sublistView(inputBytes);
    final totalSamples = framesToRead * channelCount;
    int srcByteOffset = 0;
    int dstIdx = 0;

    switch (encoding) {
      case PcmEncoding.pcm16:
        for (int i = 0; i < totalSamples; i++) {
          final sample16 = byteData.getInt16(srcByteOffset, Endian.little);
          srcByteOffset += 2;
          destinationBlock.samples[dstIdx++] = sample16 * _inv16;
        }
        break;

      case PcmEncoding.pcm24Packed:
        for (int i = 0; i < totalSamples; i++) {
          final b0 = byteData.getUint8(srcByteOffset);
          final b1 = byteData.getUint8(srcByteOffset + 1);
          final b2 = byteData.getInt8(srcByteOffset + 2); // sign-extended
          srcByteOffset += 3;
          final sample24 = (b2 << 16) | (b1 << 8) | b0;
          destinationBlock.samples[dstIdx++] = sample24 * _inv24;
        }
        break;

      case PcmEncoding.pcm32Int:
        for (int i = 0; i < totalSamples; i++) {
          final sample32 = byteData.getInt32(srcByteOffset, Endian.little);
          srcByteOffset += 4;
          destinationBlock.samples[dstIdx++] = sample32 * _inv32;
        }
        break;

      case PcmEncoding.pcmFloat32:
        for (int i = 0; i < totalSamples; i++) {
          final sampleF = byteData.getFloat32(srcByteOffset, Endian.little);
          srcByteOffset += 4;
          destinationBlock.samples[dstIdx++] = sanitizeFloat(sampleF);
        }
        break;

      case PcmEncoding.dsdOverPcm:
        // DoP marker decoding (0x05 or 0xFA in MSB with 16 DSD bitstream samples)
        for (int i = 0; i < totalSamples; i++) {
          final b0 = byteData.getUint8(srcByteOffset);
          final b1 = byteData.getUint8(srcByteOffset + 1);
          // b2 is DoP header marker
          srcByteOffset += 3;
          final pcmBits = (b1 << 8) | b0;
          final signed16 = pcmBits >= 32768 ? pcmBits - 65536 : pcmBits;
          destinationBlock.samples[dstIdx++] = signed16 * _inv16;
        }
        break;
    }

    destinationBlock.reset(framesToRead);
    return framesToRead;
  }

  /// Encodes Float32 samples from [sourceBlock] into a raw byte buffer matching [encoding].
  static Uint8List encode({
    required AudioBlock sourceBlock,
    required PcmEncoding encoding,
    int startFrame = 0,
    int? framesToEncode,
  }) {
    final channelCount = sourceBlock.channelCount;
    final bytesPerFrame = encoding.bytesPerFrame(channelCount);
    final available = sourceBlock.frameCount - startFrame;
    final requested = framesToEncode ?? available;
    final framesToWrite = math.max(0, math.min(available, requested));

    if (framesToWrite <= 0 || bytesPerFrame <= 0) {
      return Uint8List(0);
    }

    final outBytes = Uint8List(framesToWrite * bytesPerFrame);
    final byteData = ByteData.sublistView(outBytes);

    int srcIdx = startFrame * channelCount;
    int dstByteOffset = 0;
    final totalSamples = framesToWrite * channelCount;

    switch (encoding) {
      case PcmEncoding.pcm16:
        for (int i = 0; i < totalSamples; i++) {
          final clamped = clamp16(sourceBlock.samples[srcIdx++]);
          byteData.setInt16(dstByteOffset, clamped, Endian.little);
          dstByteOffset += 2;
        }
        break;

      case PcmEncoding.pcm24Packed:
        for (int i = 0; i < totalSamples; i++) {
          final sample24 = clamp24(sourceBlock.samples[srcIdx++]);
          outBytes[dstByteOffset] = sample24 & 0xFF;
          outBytes[dstByteOffset + 1] = (sample24 >> 8) & 0xFF;
          outBytes[dstByteOffset + 2] = (sample24 >> 16) & 0xFF;
          dstByteOffset += 3;
        }
        break;

      case PcmEncoding.pcm32Int:
        for (int i = 0; i < totalSamples; i++) {
          final clamped = clamp32(sourceBlock.samples[srcIdx++]);
          byteData.setInt32(dstByteOffset, clamped, Endian.little);
          dstByteOffset += 4;
        }
        break;

      case PcmEncoding.pcmFloat32:
        for (int i = 0; i < totalSamples; i++) {
          final sanitized = sanitizeFloat(sourceBlock.samples[srcIdx++]);
          byteData.setFloat32(dstByteOffset, sanitized, Endian.little);
          dstByteOffset += 4;
        }
        break;

      case PcmEncoding.dsdOverPcm:
        // DoP marker encoding
        for (int i = 0; i < totalSamples; i++) {
          final clamped = clamp16(sourceBlock.samples[srcIdx++]);
          final marker = (i % 2 == 0) ? 0x05 : 0xFA;
          outBytes[dstByteOffset] = clamped & 0xFF;
          outBytes[dstByteOffset + 1] = (clamped >> 8) & 0xFF;
          outBytes[dstByteOffset + 2] = marker;
          dstByteOffset += 3;
        }
        break;
    }

    return outBytes;
  }

  /// Clamps Float32 to 16-bit signed integer [-32768, 32767].
  static int clamp16(double sample) {
    if (sample.isNaN) return 0;
    if (sample >= 0.9999695) return 32767;
    if (sample <= -1.0) return -32768;
    return (sample * 32768.0).round().clamp(-32768, 32767);
  }

  /// Clamps Float32 to 24-bit signed integer [-8388608, 8388607].
  static int clamp24(double sample) {
    if (sample.isNaN) return 0;
    if (sample >= 0.99999988) return 8388607;
    if (sample <= -1.0) return -8388608;
    return (sample * 8388608.0).round().clamp(-8388608, 8388607);
  }

  /// Clamps Float32 to 32-bit signed integer [-2147483648, 2147483647].
  static int clamp32(double sample) {
    if (sample.isNaN) return 0;
    if (sample >= 1.0) return 2147483647;
    if (sample <= -1.0) return -2147483648;
    return (sample * 2147483648.0).round().clamp(-2147483648, 2147483647);
  }

  /// Sanitizes float against NaN, positive infinity, or negative infinity.
  static double sanitizeFloat(double sample) {
    if (sample.isNaN) return 0.0;
    if (sample > 1.0) return 1.0;
    if (sample < -1.0) return -1.0;
    return sample;
  }
}
