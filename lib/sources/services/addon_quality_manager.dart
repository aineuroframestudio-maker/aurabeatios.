import '../models/audio_quality_models.dart';

/// Intelligent Quality Mapping Engine
/// Evaluates user preferences against provider-declared capabilities and implements
/// strict fallback hierarchies, lossless validation, and Dolby Atmos negotiation.
class AddonQualityManager {
  static final AddonQualityManager instance = AddonQualityManager._internal();

  QualityPreferenceSettings preferences = QualityPreferenceSettings();

  AddonQualityManager._internal();

  /// Maps a global quality profile to the provider's best matching supported quality parameter.
  ///
  /// Fallback Hierarchies (as per BitChord protocol & system spec):
  /// - MAX: max -> hires -> lossless -> high -> low
  /// - HI-RES: hires -> lossless -> high -> low
  /// - LOSSLESS: lossless -> hires -> high -> low
  /// - HIGH: high -> max -> low
  /// - LOW: low -> high
  /// - AUTO: Wi-Fi -> max/hires/lossless; Cellular -> high/low
  String mapQuality({
    required GlobalQualityProfile requested,
    required List<String> supportedOptions,
    bool isWifi = true,
  }) {
    if (supportedOptions.isEmpty) {
      // Default to standard BitChord quality tiers
      return requested == GlobalQualityProfile.auto
          ? (isWifi ? 'lossless' : 'high')
          : requested.value;
    }

    final normalizedSupported = supportedOptions.map((e) => e.toLowerCase()).toList();

    // Helper to find first matching option in supported list
    String? findMatch(List<String> candidates) {
      for (final candidate in candidates) {
        final candLower = candidate.toLowerCase();
        for (int i = 0; i < normalizedSupported.length; i++) {
          final opt = normalizedSupported[i];
          if (opt == candLower || opt.contains(candLower) || candLower.contains(opt)) {
            return supportedOptions[i];
          }
        }
      }
      return null;
    }

    // Resolve AUTO profile first
    GlobalQualityProfile effective = requested;
    if (requested == GlobalQualityProfile.auto) {
      effective = isWifi ? preferences.wifiQuality : preferences.cellularQuality;
      if (effective == GlobalQualityProfile.auto) {
        effective = isWifi ? GlobalQualityProfile.ultraHiRes : GlobalQualityProfile.high;
      }
    }

    switch (effective) {
      case GlobalQualityProfile.ultraHiRes:
      case GlobalQualityProfile.max:
        final match = findMatch(['max', 'ultra', '192', 'hires', 'hi-res', 'lossless', 'high', 'low']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.hiResAudio:
      case GlobalQualityProfile.hires:
        final match = findMatch(['hires', 'hi-res', '96', 'max', 'lossless', 'high', 'low']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.hiResLossless:
        final match = findMatch(['hires_lossless', '48', 'hires', 'lossless', 'flac', 'max', 'high']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.lossless:
        final match = findMatch(['lossless', 'flac', 'hires', 'hi-res', 'max', 'high', 'low']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.veryHigh:
        final match = findMatch(['320', 'very_high', 'high', 'standard', 'max', 'lossless']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.high:
        final match = findMatch(['high', '256', '320', 'standard', 'max', 'lossless', 'low']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.normal:
        final match = findMatch(['normal', '128', 'standard', 'high', 'low']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.low:
        final match = findMatch(['low', 'data saver', '64', '96', '128', 'high']);
        return match ?? supportedOptions.last;

      case GlobalQualityProfile.dolbyAtmos:
        final match = findMatch(['atmos', 'dolby', 'spatial', 'max', 'hires', 'lossless']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.sony360:
        final match = findMatch(['sony360', '360', 'spatial', 'atmos', 'max', 'hires', 'lossless']);
        return match ?? supportedOptions.first;

      case GlobalQualityProfile.auto:
        return supportedOptions.first;
    }
  }

  /// Negotiate Atmos parameter based on preferences and declared settings.
  /// BitChord sends this only when Dolby is enabled and supported:
  /// e.g. atmos=auto
  String? negotiateAtmos({required bool atmosSupported}) {
    if (!atmosSupported) return null;
    final pref = preferences.dolbyAtmosPreference.toLowerCase();
    if (pref == 'off' || pref == 'stereo') return null;
    return 'auto';
  }

  /// Extracts and validates verified technical audio metadata from provider stream response.
  AudioMetadata verifyMetadata({
    required Map<String, dynamic> streamJson,
    required String sourceId,
    required String sourceName,
  }) {
    final rawFormat = (streamJson['format'] ?? '').toString().toLowerCase();
    final rawCodec = (streamJson['codec'] ?? streamJson['fileCodec'] ?? '').toString().toLowerCase();
    final rawContainer = (streamJson['container'] ?? streamJson['containerFormat'] ?? '').toString().toLowerCase();
    final rawManifest = (streamJson['manifest'] ?? streamJson['mediaType'] ?? '').toString().toLowerCase();

    // Determine Codec
    String codec = 'AAC';
    bool isLossless = false;
    bool isHiRes = false;
    bool isDolbyAtmos = false;

    if (rawCodec.contains('flac') || rawFormat.contains('flac')) {
      codec = 'FLAC';
      isLossless = true;
    } else if (rawCodec.contains('alac') || rawFormat.contains('alac')) {
      codec = 'ALAC';
      isLossless = true;
    } else if (rawCodec.contains('wav')) {
      codec = 'WAV';
      isLossless = true;
    } else if (rawCodec.contains('eac3') || rawCodec.contains('joc') || rawFormat.contains('atmos')) {
      codec = 'E-AC-3 JOC';
      isDolbyAtmos = true;
    } else if (rawCodec.contains('mp3') || rawFormat.contains('mp3')) {
      codec = 'MP3';
    } else if (rawCodec.contains('opus') || rawFormat.contains('opus')) {
      codec = 'Opus';
    } else {
      codec = 'AAC';
    }

    // Determine Container
    String container = 'mp4';
    if (rawContainer.isNotEmpty) {
      container = rawContainer;
    } else if (rawManifest == 'dash' || rawFormat == 'dash') {
      container = 'DASH MPD';
    } else if (rawManifest == 'hls' || rawFormat == 'hls') {
      container = 'HLS M3U8';
    } else if (isLossless) {
      container = codec.toLowerCase();
    }

    // Parse Sample Rate
    int? sampleRateHz;
    final srVal = streamJson['sampleRate'];
    if (srVal != null) {
      if (srVal is num) {
        sampleRateHz = srVal.toInt();
      } else if (srVal is String) {
        sampleRateHz = int.tryParse(srVal);
      }
    }

    // Parse Bit Depth
    int? bitDepth;
    final bdVal = streamJson['bitDepth'];
    if (bdVal != null) {
      if (bdVal is num) {
        bitDepth = bdVal.toInt();
      } else if (bdVal is String) {
        bitDepth = int.tryParse(bdVal);
      }
    }

    // Hi-Res Audio Verification:
    // Only audio with > 48,000 Hz sample rate OR > 16-bit depth is genuine Hi-Res.
    // Standard 44.1 kHz / 16-bit is CD Lossless, NEVER marked as Hi-Res.
    if (isLossless) {
      if ((sampleRateHz != null && sampleRateHz > 48000) || (bitDepth != null && bitDepth > 16)) {
        isHiRes = true;
      }
    }

    // Parse Bitrate
    int? bitrateKbps;
    final brVal = streamJson['bitrate'];
    if (brVal != null) {
      if (brVal is num) {
        bitrateKbps = brVal > 10000 ? (brVal / 1000).round() : brVal.toInt();
      } else if (brVal is String) {
        final parsed = double.tryParse(brVal);
        if (parsed != null) {
          bitrateKbps = parsed > 10000 ? (parsed / 1000).round() : parsed.toInt();
        }
      }
    } else if (isLossless) {
      // Theoretical average for 16/44.1 is ~850-1411 kbps; 24/96 is ~2300-4608 kbps
      if (isHiRes && bitDepth == 24 && sampleRateHz == 192000) {
        bitrateKbps = 9216;
      } else if (isHiRes && bitDepth == 24 && sampleRateHz == 96000) {
        bitrateKbps = 4608;
      } else {
        bitrateKbps = 1411;
      }
    } else if (codec == 'AAC' || codec == 'MP3') {
      bitrateKbps = 320;
    }

    // Dolby Atmos Detection
    final audioMode = (streamJson['audioMode'] ?? '').toString().toUpperCase();
    final audioModes = streamJson['audioModes'] is List
        ? (streamJson['audioModes'] as List).map((e) => e.toString().toUpperCase()).toList()
        : <String>[];
    final atmosFlag = streamJson['atmos'] == true || streamJson['atmos'] == 1;

    if (audioMode == 'DOLBY_ATMOS' || audioModes.contains('DOLBY_ATMOS') || atmosFlag || codec == 'E-AC-3 JOC' || rawCodec.contains('eac3') || rawCodec.contains('joc')) {
      isDolbyAtmos = true;
      codec = 'E-AC-3 JOC';
    }

    int channels = 2;
    if (isDolbyAtmos) {
      channels = 8; // 7.1.4 object spatial rendering bed
      bitrateKbps ??= 768;
      sampleRateHz ??= 48000;
    }

    String streamType = 'Direct HTTP';
    if (rawManifest == 'dash' || rawFormat == 'dash') {
      streamType = 'MPEG-DASH Dynamic Streaming';
    } else if (rawManifest == 'hls' || rawFormat == 'hls') {
      streamType = 'HLS Adaptive Bitrate';
    }

    return AudioMetadata(
      codec: codec,
      container: container,
      bitrateKbps: bitrateKbps,
      sampleRateHz: sampleRateHz,
      bitDepth: bitDepth,
      channels: channels,
      isLossless: isLossless,
      isHiRes: isHiRes,
      isDolbyAtmos: isDolbyAtmos,
      sourceId: sourceId,
      sourceName: sourceName,
      streamType: streamType,
    );
  }
}
