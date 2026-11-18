// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord audio engine (DSD Format Modeling & DSF/DFF Container Parsers).

import 'dart:convert';
import 'dart:typed_data';
import '../negotiator/output_negotiator.dart';

/// DSD file container format.
enum DsdContainer {
  dsf,
  dff,
}

/// Structured diagnostic report on DSD over PCM (DoP v1.0) transmission capability.
class DopCapability {
  final bool isSupported;
  final int requiredPcmRateHz;
  final int requiredBitDepth;
  final bool routeSupportsRate;
  final bool routeSupportsDepth;
  final String statusDescription;

  const DopCapability({
    required this.isSupported,
    required this.requiredPcmRateHz,
    required this.requiredBitDepth,
    required this.routeSupportsRate,
    required this.routeSupportsDepth,
    required this.statusDescription,
  });

  Map<String, dynamic> toMap() => {
        'isSupported': isSupported,
        'requiredPcmRateHz': requiredPcmRateHz,
        'requiredBitDepth': requiredBitDepth,
        'routeSupportsRate': routeSupportsRate,
        'routeSupportsDepth': routeSupportsDepth,
        'statusDescription': statusDescription,
      };
}

/// DSD stream descriptor modeling bit rate, channels, decimation, and container framing.
class DsdFormat {
  final DsdContainer container;
  final int bitRate;
  final int channels;
  final int sampleCount;
  final int dataOffset;
  final int dataBytes;
  final bool leastSignificantBitFirst;
  final int blockBytes;

  const DsdFormat({
    required this.container,
    required this.bitRate,
    required this.channels,
    required this.sampleCount,
    required this.dataOffset,
    required this.dataBytes,
    this.leastSignificantBitFirst = false,
    this.blockBytes = 4096,
  });

  /// Canonical target decimation PCM sample rate: 176.4 kHz.
  static const int pcmDecimationRate = 176400;

  /// Instance getter for decimation PCM sample rate.
  int get pcmRate => pcmDecimationRate;

  /// Decimation factor from 1-bit DSD to 176.4 kHz PCM.
  int get decimation => bitRate ~/ pcmRate;

  /// Number of equivalent 176.4 kHz PCM frames.
  int get pcmFrames => (sampleCount + decimation - 1) ~/ decimation;

  /// Duration in microseconds.
  int get durationUs => (sampleCount * 1000000) ~/ bitRate;

  /// Duration in seconds.
  double get durationSeconds => sampleCount / bitRate;

  /// Bytes per channel in 1-bit representation.
  int get bytesPerChannel => (sampleCount + 7) ~/ 8;

  /// Required PCM sample rate for transmitting this DSD stream via DoP (DSD_RATE / 16).
  int get requiredDopPcmRate => bitRate ~/ 16;

  /// Supported DSD rates (DSD64 to DSD1024).
  static const List<int> supportedBitRates = [
    2822400, // DSD64  (64 * 44.1 kHz)
    5644800, // DSD128 (128 * 44.1 kHz)
    11289600, // DSD256 (256 * 44.1 kHz)
    22579200, // DSD512 (512 * 44.1 kHz)
    45158400, // DSD1024
  ];

  static bool supportsBitRate(int rate) => supportedBitRates.contains(rate);

  /// Computes target PCM frame for seeking.
  int seekFrame(double timeSeconds) {
    if (timeSeconds <= 0.0) return 0;
    if (timeSeconds >= durationSeconds) return pcmFrames;
    return (timeSeconds * pcmRate).toInt().clamp(0, pcmFrames);
  }

  /// Evaluates whether native raw software decimation is available on the current runtime.
  ///
  /// Strictly reports false on standard Flutter/Dart environments because the proprietary
  /// C++ JNI library (bitchord_dsd) is not compiled or bundled.
  static bool get hasNativeSoftwareDecimator => false;

  /// Evaluates DoP v1.0 transmission capability for this DSD stream against an output route.
  DopCapability reportDopCapability(RouteDescriptor? route) {
    final neededRate = requiredDopPcmRate;
    const neededDepth = 24;

    if (route == null) {
      return DopCapability(
        isSupported: false,
        requiredPcmRateHz: neededRate,
        requiredBitDepth: neededDepth,
        routeSupportsRate: false,
        routeSupportsDepth: false,
        statusDescription: 'No active hardware output route specified for DoP evaluation.',
      );
    }

    final rateOk = route.advertisedSampleRates.contains(neededRate) ||
        route.advertisedSampleRates.any((r) => r >= neededRate);
    final depthOk = route.advertisedBitDepths.contains(neededDepth) ||
        route.advertisedBitDepths.any((d) => d >= neededDepth);
    final isSupported = rateOk && depthOk && route.isDirectCapable;

    String reason;
    if (isSupported) {
      reason = 'Route "${route.deviceName}" supports direct 24-bit / $neededRate Hz PCM for DoP pass-through.';
    } else if (!route.isDirectCapable) {
      reason = 'Route "${route.deviceName}" does not support direct hardware pass-through mode.';
    } else if (!rateOk) {
      reason = 'Route "${route.deviceName}" does not advertise the required $neededRate Hz PCM rate.';
    } else {
      reason = 'Route "${route.deviceName}" does not support 24-bit PCM depth required for DoP.';
    }

    return DopCapability(
      isSupported: isSupported,
      requiredPcmRateHz: neededRate,
      requiredBitDepth: neededDepth,
      routeSupportsRate: rateOk,
      routeSupportsDepth: depthOk,
      statusDescription: reason,
    );
  }

  /// Human-readable tier label (e.g. "DSD64 (2.8224 MHz)").
  String get tierLabel {
    switch (bitRate) {
      case 2822400:
        return 'DSD64 (2.8224 MHz)';
      case 5644800:
        return 'DSD128 (5.6448 MHz)';
      case 11289600:
        return 'DSD256 (11.2896 MHz)';
      case 22579200:
        return 'DSD512 (22.5792 MHz)';
      default:
        return 'DSD (${(bitRate / 1000000.0).toStringAsFixed(2)} MHz)';
    }
  }
}

/// Parses DSF and DFF chunk headers and validates container metadata.
class DsdHeaderParser {
  /// Detects whether byte buffer belongs to DSF (Sony) or DFF (Philips DSDIFF).
  static DsdContainer detectContainer(Uint8List headerBytes) {
    if (headerBytes.length < 4) {
      throw const FormatException('Buffer too small to detect DSD container format');
    }
    final magic = ascii.decode(headerBytes.sublist(0, 4), allowInvalid: true);
    if (magic == 'DSD ') {
      return DsdContainer.dsf;
    }
    if (magic == 'FRM8') {
      return DsdContainer.dff;
    }
    throw FormatException('Unrecognized DSD header magic: "$magic" (expected "DSD " or "FRM8")');
  }

  /// Parses DSF 'fmt ' chunk bytes (at least 40 bytes) and creates a validated [DsdFormat].
  static DsdFormat parseDsf({
    required Uint8List formatChunkBytes,
    required int dataOffset,
    required int dataBytes,
  }) {
    if (formatChunkBytes.length < 40) {
      throw FormatException('Incomplete DSF format chunk: ${formatChunkBytes.length} bytes');
    }

    final bd = ByteData.sublistView(formatChunkBytes);
    final formatVersion = bd.getUint32(0, Endian.little);
    final formatId = bd.getUint32(4, Endian.little);

    if (formatVersion != 1 || formatId != 0) {
      throw FormatException('Unsupported DSF format: version=$formatVersion, id=$formatId');
    }

    final channelNum = bd.getUint32(12, Endian.little);

    if (channelNum < 1 || channelNum > 2) {
      throw FormatException('AuraBeat supports mono or stereo DSD; found $channelNum channels');
    }

    final sampleRate = bd.getUint32(16, Endian.little);
    final bitsPerSample = bd.getUint32(20, Endian.little);
    final sampleCount = bd.getUint64(24, Endian.little);
    final blockSize = bd.getUint32(32, Endian.little);

    if (!DsdFormat.supportsBitRate(sampleRate)) {
      throw FormatException('Unsupported DSD sample rate: $sampleRate Hz');
    }

    if (blockSize != 4096) {
      throw FormatException('Unsupported DSF block size: $blockSize (expected 4096)');
    }

    return DsdFormat(
      container: DsdContainer.dsf,
      bitRate: sampleRate,
      channels: channelNum,
      sampleCount: sampleCount,
      dataOffset: dataOffset,
      dataBytes: dataBytes,
      leastSignificantBitFirst: bitsPerSample == 1,
      blockBytes: blockSize,
    );
  }

  /// Parses Philips DSDIFF (DFF) chunk hierarchy (FRM8, PROP, SND, FS, CHNL, CMPR, DSD).
  static DsdFormat parseDff({
    required Uint8List dffBytes,
  }) {
    if (dffBytes.length < 32) {
      throw const FormatException('Incomplete DFF file header: buffer too small');
    }

    final bd = ByteData.sublistView(dffBytes);
    final magic = ascii.decode(dffBytes.sublist(0, 4), allowInvalid: true);
    if (magic != 'FRM8') {
      throw FormatException('Invalid DFF header: expected "FRM8", got "$magic"');
    }

    // Form type at offset 12 must be 'DSD '
    final formType = ascii.decode(dffBytes.sublist(12, 16), allowInvalid: true);
    if (formType != 'DSD ') {
      throw FormatException('Invalid DFF form type: expected "DSD ", got "$formType"');
    }

    int sampleRate = 2822400; // default DSD64
    int channels = 2;
    int dataOffset = 0;
    int dataBytes = 0;
    bool isCompressed = false;

    // Scan chunks inside FRM8
    int offset = 16;
    while (offset + 12 <= dffBytes.length) {
      final chunkId = ascii.decode(dffBytes.sublist(offset, offset + 4), allowInvalid: true);
      final chunkSize = bd.getUint64(offset + 4, Endian.big);
      final payloadOffset = offset + 12;

      if (chunkId == 'PROP') {
        // Property chunk contains sub-chunks
        final propType = ascii.decode(dffBytes.sublist(payloadOffset, payloadOffset + 4), allowInvalid: true);
        if (propType == 'SND ') {
          int propSubOffset = payloadOffset + 4;
          final propEnd = payloadOffset + chunkSize;
          while (propSubOffset + 12 <= propEnd && propSubOffset + 12 <= dffBytes.length) {
            final subId = ascii.decode(dffBytes.sublist(propSubOffset, propSubOffset + 4), allowInvalid: true);
            final subSize = bd.getUint64(propSubOffset + 4, Endian.big);
            final subPayload = propSubOffset + 12;

            if (subId == 'FS  ' && subPayload + 4 <= dffBytes.length) {
              sampleRate = bd.getUint32(subPayload, Endian.big);
            } else if (subId == 'CHNL' && subPayload + 2 <= dffBytes.length) {
              channels = bd.getUint16(subPayload, Endian.big);
            } else if (subId == 'CMPR' && subPayload + 4 <= dffBytes.length) {
              final cmprType = ascii.decode(dffBytes.sublist(subPayload, subPayload + 4), allowInvalid: true);
              if (cmprType != 'DSD ') {
                isCompressed = true;
              }
            }

            // Chunks in IFF/RIFF are padded to even length
            final step = 12 + subSize + (subSize % 2 == 1 ? 1 : 0);
            propSubOffset += step;
          }
        }
      } else if (chunkId == 'DSD ') {
        dataOffset = payloadOffset;
        dataBytes = chunkSize;
      }

      final chunkStep = 12 + chunkSize + (chunkSize % 2 == 1 ? 1 : 0);
      offset += chunkStep;
    }

    if (isCompressed) {
      throw const FormatException(
        'DST compression detected: uncompressed DSDIFF stream expected. Missing Philips DST decimator.',
      );
    }

    if (channels < 1 || channels > 2) {
      throw FormatException('AuraBeat supports mono or stereo DSD; found $channels channels in DFF');
    }

    final totalBits = dataBytes * 8;
    final sampleCount = channels > 0 ? (totalBits ~/ channels) : 0;

    return DsdFormat(
      container: DsdContainer.dff,
      bitRate: sampleRate,
      channels: channels,
      sampleCount: sampleCount,
      dataOffset: dataOffset,
      dataBytes: dataBytes,
      leastSignificantBitFirst: false, // DFF stores MSB first
      blockBytes: 4096,
    );
  }

  /// Automatically detects container and parses format from full or partial file bytes.
  static DsdFormat parseHeader(Uint8List fileBytes) {
    final container = detectContainer(fileBytes);
    if (container == DsdContainer.dsf) {
      // Find 'fmt ' chunk
      final bd = ByteData.sublistView(fileBytes);
      int offset = 28; // Skip 28-byte DSD chunk header
      Uint8List? fmtBytes;
      int dataOffset = 0;
      int dataBytes = 0;

      while (offset + 12 <= fileBytes.length) {
        final chunkId = ascii.decode(fileBytes.sublist(offset, offset + 4), allowInvalid: true);
        final chunkSize = bd.getUint64(offset + 4, Endian.little);
        if (chunkId == 'fmt ') {
          fmtBytes = fileBytes.sublist(offset + 12, offset + 12 + (chunkSize - 12));
        } else if (chunkId == 'data') {
          dataOffset = offset + 12;
          dataBytes = chunkSize - 12;
        }
        offset += chunkSize;
      }

      if (fmtBytes == null) {
        throw const FormatException('Missing "fmt " chunk in DSF file');
      }
      return parseDsf(formatChunkBytes: fmtBytes, dataOffset: dataOffset, dataBytes: dataBytes);
    } else {
      return parseDff(dffBytes: fileBytes);
    }
  }
}
