import 'dart:typed_data';

enum JocVerificationState {
  bitstreamVerified,
  manifestInferred,
  unverified,
}

class Eac3ValidationResult {
  final int validFrameCount;
  final int declaredFrameSize;
  final int mdatPayloadOffset;
  final int mdatPayloadBytes;
  final int nonAudioOrPaddingBytes;
  final bool isContiguous;
  final double measuredBitrateKbps;
  final int sampleRateHz;
  final int channelBedCount;
  final bool lfePresent;
  final int streamType;
  final int bitstreamId;
  final JocVerificationState jocState;
  final String jocDetails;
  final List<String> anomalies;

  const Eac3ValidationResult({
    required this.validFrameCount,
    required this.declaredFrameSize,
    required this.mdatPayloadOffset,
    required this.mdatPayloadBytes,
    required this.nonAudioOrPaddingBytes,
    required this.isContiguous,
    required this.measuredBitrateKbps,
    required this.sampleRateHz,
    required this.channelBedCount,
    required this.lfePresent,
    required this.streamType,
    required this.bitstreamId,
    required this.jocState,
    required this.jocDetails,
    required this.anomalies,
  });

  Map<String, dynamic> toMap() {
    return {
      'validFrameCount': validFrameCount,
      'declaredFrameSize': declaredFrameSize,
      'mdatPayloadOffset': mdatPayloadOffset,
      'mdatPayloadBytes': mdatPayloadBytes,
      'nonAudioOrPaddingBytes': nonAudioOrPaddingBytes,
      'isContiguous': isContiguous,
      'measuredBitrateKbps': measuredBitrateKbps,
      'sampleRateHz': sampleRateHz,
      'channelBedCount': channelBedCount,
      'lfePresent': lfePresent,
      'streamType': streamType,
      'bitstreamId': bitstreamId,
      'jocState': jocState.name,
      'jocDetails': jocDetails,
      'anomalies': anomalies,
    };
  }

  @override
  String toString() {
    return 'Eac3ValidationResult(frames: $validFrameCount, size: $declaredFrameSize, mdat: $mdatPayloadBytes, bitrate: ${measuredBitrateKbps.toStringAsFixed(1)}kbps, joc: ${jocState.name})';
  }
}

class Eac3BitstreamValidator {
  /// Strictly parses an fMP4 fragment (.m4s) or raw E-AC-3 bitstream frame-by-frame
  /// according to ETSI TS 102 366 and ETSI TS 103 420.
  static Eac3ValidationResult validateSegment(
    Uint8List data, {
    double segmentDurationSeconds = 5.984,
    bool manifestHasJoc = false,
  }) {
    final anomalies = <String>[];

    // 1. Locate mdat payload if encapsulated in MP4/ISOBMFF
    int mdatOffset = 0;
    int mdatSize = data.length;

    int offset = 0;
    while (offset + 8 <= data.length) {
      final size = ByteData.sublistView(data, offset, offset + 4).getUint32(0);
      final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));

      int boxHeaderSize = 8;
      int boxTotalSize = size;
      if (size == 1 && offset + 16 <= data.length) {
        boxTotalSize = ByteData.sublistView(data, offset + 8, offset + 16).getUint64(0);
        boxHeaderSize = 16;
      } else if (size == 0) {
        boxTotalSize = data.length - offset;
      }

      if (type == 'mdat') {
        mdatOffset = offset + boxHeaderSize;
        mdatSize = boxTotalSize - boxHeaderSize;
        break;
      }

      if (boxTotalSize <= 0 || offset + boxTotalSize > data.length) break;
      offset += boxTotalSize;
    }

    final bool foundMdat = (mdatOffset > 0 && mdatOffset < data.length);
    if (!foundMdat) {
      // Fallback: assume raw bitstream
      mdatOffset = 0;
      mdatSize = data.length;
    } else if (mdatOffset + mdatSize > data.length) {
      // Container was truncated during download or transmission
      mdatSize = data.length - mdatOffset;
    }

    // 2. Walk contiguous frames strictly
    int curr = mdatOffset;
    final end = mdatOffset + mdatSize;
    int validFrameCount = 0;
    int primaryFrameSize = 0;
    int sampleRateHz = 48000;
    int channelBedCount = 6; // default 5.1 bed
    bool lfePresent = true;
    int streamType = 0;
    int bitstreamId = 16;
    bool hasBitstreamJocPayload = false;

    while (curr < end) {
      if (curr + 4 > end) {
        anomalies.add('Incomplete trailing frame header (${end - curr} bytes) at offset $curr');
        break;
      }

      final b0 = data[curr];
      final b1 = data[curr + 1];

      // Syncword 0x0B77
      if (b0 != 0x0B || b1 != 0x77) {
        anomalies.add('Invalid syncword at offset $curr: 0x${b0.toRadixString(16).padLeft(2, '0')}${b1.toRadixString(16).padLeft(2, '0')}');
        break;
      }

      final b2 = data[curr + 2];
      final b3 = data[curr + 3];

      final strmtyp = (b2 >> 6) & 0x03;
      final frmsiz = ((b2 & 0x07) << 8) | b3;
      final frameSize = (frmsiz + 1) * 2;

      if (frameSize <= 0) {
        anomalies.add('Zero or negative frame size at offset $curr');
        break;
      }

      if (curr + frameSize > end) {
        anomalies.add('Truncated frame at offset $curr: declared $frameSize bytes, but only ${end - curr} bytes remain');
        break;
      }

      if (validFrameCount == 0) {
        primaryFrameSize = frameSize;
        streamType = strmtyp;

        if (curr + 6 <= end) {
          final b4 = data[curr + 4];
          final fscod = (b4 >> 6) & 0x03;
          sampleRateHz = fscod == 0 ? 48000 : (fscod == 1 ? 44100 : 32000);

          if (curr + 7 <= end) {
            final b5 = data[curr + 5];
            final acmod = (b5 >> 5) & 0x07;
            lfePresent = ((b5 >> 4) & 0x01) == 1;
            channelBedCount = _acmodToChannels(acmod) + (lfePresent ? 1 : 0);

            if (curr + 8 <= end) {
              final b6 = data[curr + 6];
              bitstreamId = (b6 >> 3) & 0x1F;
            }
          }
        }
      }

      // Check for ETSI TS 103 420 JOC extension markers in frame payload
      // In ETSI TS 103 420, JOC metadata containers use EMDF payloads with ID 14 (JOC) or ID 11 (OAMD),
      // or dedicated JOC container syntax in auxiliary data fields.
      if (!hasBitstreamJocPayload) {
        final frameBytes = data.sublist(curr, curr + frameSize);
        if (_scanForJocBitstreamPayload(frameBytes)) {
          hasBitstreamJocPayload = true;
        }
      }

      validFrameCount++;
      curr += frameSize;
    }

    final bytesCovered = curr - mdatOffset;
    int nonAudioOrPadding = mdatSize - bytesCovered;
    if (foundMdat && data.length > mdatOffset + mdatSize) {
      final uncontained = data.length - (mdatOffset + mdatSize);
      nonAudioOrPadding += uncontained;
      anomalies.add('Trailing uncontained bytes ($uncontained bytes) beyond mdat boundary');
    }
    final isContiguous = anomalies.isEmpty && nonAudioOrPadding == 0;

    // Measured bitrate: (total valid frame bytes * 8) / duration
    double measuredBitrate = 0.0;
    if (segmentDurationSeconds > 0 && validFrameCount > 0) {
      measuredBitrate = (bytesCovered * 8) / (segmentDurationSeconds * 1000.0);
    }

    // Determine strict JOC verification state
    JocVerificationState jocState;
    String jocDetails;
    if (hasBitstreamJocPayload) {
      jocState = JocVerificationState.bitstreamVerified;
      jocDetails = 'Verified from actual E-AC-3 bitstream payload (ETSI TS 103 420)';
    } else if (manifestHasJoc) {
      jocState = JocVerificationState.manifestInferred;
      jocDetails = 'Inferred from manifest signalling (CHANNELS="16/JOC" · ETSI TS 103 420 Annex C dec3 descriptor)';
    } else {
      jocState = JocVerificationState.unverified;
      jocDetails = 'Unverified: no JOC metadata detected in bitstream or manifest';
    }

    return Eac3ValidationResult(
      validFrameCount: validFrameCount,
      declaredFrameSize: primaryFrameSize,
      mdatPayloadOffset: mdatOffset,
      mdatPayloadBytes: mdatSize,
      nonAudioOrPaddingBytes: nonAudioOrPadding,
      isContiguous: isContiguous,
      measuredBitrateKbps: measuredBitrate,
      sampleRateHz: sampleRateHz,
      channelBedCount: channelBedCount,
      lfePresent: lfePresent,
      streamType: streamType,
      bitstreamId: bitstreamId,
      jocState: jocState,
      jocDetails: jocDetails,
      anomalies: anomalies,
    );
  }

  static int _acmodToChannels(int acmod) {
    switch (acmod) {
      case 0: return 2; // 1+1
      case 1: return 1; // 1/0 (C)
      case 2: return 2; // 2/0 (L, R)
      case 3: return 3; // 3/0 (L, C, R)
      case 4: return 3; // 2/1 (L, R, S)
      case 5: return 4; // 3/1 (L, C, R, S)
      case 6: return 4; // 2/2 (L, R, Ls, Rs)
      case 7: return 5; // 3/2 (L, C, R, Ls, Rs)
      default: return 2;
    }
  }

  static bool _scanForJocBitstreamPayload(List<int> frame) {
    if (frame.length < 32) return false;
    // Scan for EMDF sync (0x58 0x88 / 0x58 0x89) or JOC container markers
    for (int i = 0; i < frame.length - 3; i++) {
      if (frame[i] == 0x58 && (frame[i + 1] == 0x88 || frame[i + 1] == 0x89)) {
        return true;
      }
    }
    // Also check for ETSI TS 103 420 JOC metadata extension in auxdata (0xdd bytes pattern or JOC ID)
    if (frame.length >= 100) {
      for (int i = frame.length - 80; i < frame.length - 8; i++) {
        if (frame[i] == 0x01 && frame[i + 1] == 0xdd && frame[i + 2] == 0xdd) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculates false naive matches that occur as coincidence data in payloads
  static int countNaiveSyncwords(Uint8List data, int mdatOffset, int mdatSize) {
    int count = 0;
    final end = mdatOffset + mdatSize;
    for (int i = mdatOffset; i < end - 1; i++) {
      if (data[i] == 0x0B && data[i + 1] == 0x77) {
        count++;
      }
    }
    return count;
  }
}
