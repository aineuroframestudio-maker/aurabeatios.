// AuraBeat Audio Quality & Stream Models
// Comprehensive models for audio quality profiles, stream metadata, format negotiation, and preferences.

enum GlobalQualityProfile {
  max,
  hires,
  lossless,
  high,
  low,
  auto,
  // AuraBeat iOS Master Specification Quality Tiers
  normal,
  veryHigh,
  hiResLossless,
  hiResAudio,
  ultraHiRes,
  dolbyAtmos,
  sony360,
}

extension GlobalQualityProfileExt on GlobalQualityProfile {
  String get value {
    switch (this) {
      case GlobalQualityProfile.max:
      case GlobalQualityProfile.ultraHiRes:
        return 'max';
      case GlobalQualityProfile.hires:
      case GlobalQualityProfile.hiResAudio:
        return 'hires';
      case GlobalQualityProfile.hiResLossless:
        return 'hires_lossless';
      case GlobalQualityProfile.lossless:
        return 'lossless';
      case GlobalQualityProfile.veryHigh:
        return 'very_high';
      case GlobalQualityProfile.high:
        return 'high';
      case GlobalQualityProfile.normal:
        return 'normal';
      case GlobalQualityProfile.low:
        return 'low';
      case GlobalQualityProfile.dolbyAtmos:
        return 'atmos';
      case GlobalQualityProfile.sony360:
        return 'sony360';
      case GlobalQualityProfile.auto:
        return 'auto';
    }
  }

  String get displayName {
    switch (this) {
      case GlobalQualityProfile.max:
      case GlobalQualityProfile.ultraHiRes:
        return 'Ultra Hi-Res (24-bit / 192 kHz FLAC/ALAC)';
      case GlobalQualityProfile.hires:
      case GlobalQualityProfile.hiResAudio:
        return 'Hi-Res Audio (24-bit / 96 kHz Master)';
      case GlobalQualityProfile.hiResLossless:
        return 'Hi-Res Lossless (24-bit / 48 kHz Studio)';
      case GlobalQualityProfile.lossless:
        return 'CD Lossless (16-bit / 44.1 kHz FLAC/ALAC)';
      case GlobalQualityProfile.veryHigh:
        return 'Very High (320 kbps MP3)';
      case GlobalQualityProfile.high:
        return 'High (256 kbps AAC)';
      case GlobalQualityProfile.normal:
        return 'Normal (128 kbps AAC/MP3)';
      case GlobalQualityProfile.low:
        return 'Low (64 kbps Data Saver)';
      case GlobalQualityProfile.dolbyAtmos:
        return 'Dolby Atmos Spatial Audio (7.1.4)';
      case GlobalQualityProfile.sony360:
        return 'Sony 360° Reality Audio (360° Spatial)';
      case GlobalQualityProfile.auto:
        return 'Auto (Adaptive Network Streaming)';
    }
  }

  String get label => badgeLabel;

  String get pickerLabel {
    switch (this) {
      case GlobalQualityProfile.max:
      case GlobalQualityProfile.ultraHiRes:
        return 'Ultra Hi-Res (9216 kbps)';
      case GlobalQualityProfile.hires:
      case GlobalQualityProfile.hiResAudio:
        return 'Hi-Res Audio (4608 kbps)';
      case GlobalQualityProfile.hiResLossless:
        return 'Hi-Res Lossless (2304 kbps)';
      case GlobalQualityProfile.lossless:
        return 'CD Lossless (1411 kbps)';
      case GlobalQualityProfile.veryHigh:
        return 'Very High (320 kbps)';
      case GlobalQualityProfile.high:
        return 'High (256 kbps)';
      case GlobalQualityProfile.normal:
        return 'Normal (128 kbps)';
      case GlobalQualityProfile.low:
        return 'Low Data Saver (64 kbps)';
      case GlobalQualityProfile.dolbyAtmos:
        return 'Dolby Atmos (768 kbps)';
      case GlobalQualityProfile.sony360:
        return 'Sony 360° RA (1536 kbps)';
      case GlobalQualityProfile.auto:
        return 'Auto (Adaptive Network)';
    }
  }

  static const List<String> pickerOptions = [
    'Ultra Hi-Res (9216 kbps)',
    'Hi-Res Audio (4608 kbps)',
    'Hi-Res Lossless (2304 kbps)',
    'CD Lossless (1411 kbps)',
    'Very High (320 kbps)',
    'High (256 kbps)',
    'Normal (128 kbps)',
    'Low Data Saver (64 kbps)',
    'Dolby Atmos (768 kbps)',
    'Sony 360° RA (1536 kbps)',
    'Auto (Adaptive Network)',
  ];

  static GlobalQualityProfile fromPickerLabel(String pickerLabel) {
    if (pickerLabel.contains('9216') || pickerLabel.contains('Ultra')) return GlobalQualityProfile.ultraHiRes;
    if (pickerLabel.contains('4608') || pickerLabel.contains('Hi-Res Audio')) return GlobalQualityProfile.hiResAudio;
    if (pickerLabel.contains('2304') || pickerLabel.contains('Hi-Res Lossless')) return GlobalQualityProfile.hiResLossless;
    if (pickerLabel.contains('1411') || pickerLabel.contains('CD Lossless')) return GlobalQualityProfile.lossless;
    if (pickerLabel.contains('320') || pickerLabel.contains('Very High')) return GlobalQualityProfile.veryHigh;
    if (pickerLabel.contains('256') || pickerLabel.contains('High')) return GlobalQualityProfile.high;
    if (pickerLabel.contains('128') || pickerLabel.contains('Normal')) return GlobalQualityProfile.normal;
    if (pickerLabel.contains('64') || pickerLabel.contains('Low')) return GlobalQualityProfile.low;
    if (pickerLabel.contains('Atmos') || pickerLabel.contains('768')) return GlobalQualityProfile.dolbyAtmos;
    if (pickerLabel.contains('360') || pickerLabel.contains('1536')) return GlobalQualityProfile.sony360;
    return GlobalQualityProfile.auto;
  }

  String get badgeLabel {
    switch (this) {
      case GlobalQualityProfile.max:
      case GlobalQualityProfile.ultraHiRes:
        return 'ULTRA HI-RES';
      case GlobalQualityProfile.hires:
      case GlobalQualityProfile.hiResAudio:
        return 'HI-RES 96k';
      case GlobalQualityProfile.hiResLossless:
        return 'HI-RES 48k';
      case GlobalQualityProfile.lossless:
        return 'LOSSLESS';
      case GlobalQualityProfile.veryHigh:
        return '320k';
      case GlobalQualityProfile.high:
        return 'HIGH 256k';
      case GlobalQualityProfile.normal:
        return '128k';
      case GlobalQualityProfile.low:
        return '64k';
      case GlobalQualityProfile.dolbyAtmos:
        return 'ATMOS';
      case GlobalQualityProfile.sony360:
        return '360 RA';
      case GlobalQualityProfile.auto:
        return 'AUTO';
    }
  }
}

class QualityPreferenceSettings {
  GlobalQualityProfile streamingQuality;
  GlobalQualityProfile wifiQuality;
  GlobalQualityProfile cellularQuality;
  String preferredFormat; // 'Auto', 'FLAC', 'ALAC', 'AAC', 'MP3'
  bool preferFlac;
  bool preferHiRes;
  bool preferLossless;
  String dolbyAtmosPreference; // 'auto', 'stereo'
  bool allowLossyFallback;
  bool strictLossless;

  QualityPreferenceSettings({
    this.streamingQuality = GlobalQualityProfile.ultraHiRes,
    this.wifiQuality = GlobalQualityProfile.ultraHiRes,
    this.cellularQuality = GlobalQualityProfile.high,
    this.preferredFormat = 'Auto',
    this.preferFlac = true,
    this.preferHiRes = true,
    this.preferLossless = true,
    this.dolbyAtmosPreference = 'auto',
    this.allowLossyFallback = true,
    this.strictLossless = false,
  });

  Map<String, dynamic> toJson() => {
    'streamingQuality': streamingQuality.value,
    'wifiQuality': wifiQuality.value,
    'cellularQuality': cellularQuality.value,
    'preferredFormat': preferredFormat,
    'preferFlac': preferFlac,
    'preferHiRes': preferHiRes,
    'preferLossless': preferLossless,
    'dolbyAtmosPreference': dolbyAtmosPreference,
    'allowLossyFallback': allowLossyFallback,
    'strictLossless': strictLossless,
  };

  factory QualityPreferenceSettings.fromJson(Map<String, dynamic> json) {
    GlobalQualityProfile parseProfile(String? val, GlobalQualityProfile fallback) {
      if (val == null) return fallback;
      return GlobalQualityProfile.values.firstWhere(
        (e) => e.value == val,
        orElse: () => fallback,
      );
    }

    return QualityPreferenceSettings(
      streamingQuality: parseProfile(json['streamingQuality'], GlobalQualityProfile.hires),
      wifiQuality: parseProfile(json['wifiQuality'], GlobalQualityProfile.max),
      cellularQuality: parseProfile(json['cellularQuality'], GlobalQualityProfile.high),
      preferredFormat: json['preferredFormat'] ?? 'Auto',
      preferFlac: json['preferFlac'] ?? true,
      preferHiRes: json['preferHiRes'] ?? true,
      preferLossless: json['preferLossless'] ?? true,
      dolbyAtmosPreference: json['dolbyAtmosPreference'] ?? 'auto',
      allowLossyFallback: json['allowLossyFallback'] ?? true,
      strictLossless: json['strictLossless'] ?? false,
    );
  }
}

/// Verified technical audio metadata for the playing or resolved track.
class AudioMetadata {
  final String codec; // e.g., 'FLAC', 'AAC', 'MP3', 'E-AC-3 JOC'
  final String container; // e.g., 'flac', 'mp4', 'dash', 'hls'
  final int? bitrateKbps;
  final int? sampleRateHz; // e.g., 44100, 48000, 96000, 192000
  final int? bitDepth; // e.g., 16, 24
  final int channels; // e.g., 2 for stereo, 6 for 5.1, 8 for Atmos
  final bool isLossless;
  final bool isHiRes;
  final bool isDolbyAtmos;
  final String sourceId;
  final String sourceName;
  final String streamType; // 'Direct HTTP', 'HLS', 'DASH'

  const AudioMetadata({
    required this.codec,
    required this.container,
    this.bitrateKbps,
    this.sampleRateHz,
    this.bitDepth,
    this.channels = 2,
    this.isLossless = false,
    this.isHiRes = false,
    this.isDolbyAtmos = false,
    required this.sourceId,
    required this.sourceName,
    this.streamType = 'Direct HTTP',
  });

  String get summaryQualityLabel {
    final br = bitrateKbps != null ? ' · $bitrateKbps kbps' : '';
    if (isDolbyAtmos && isHiRes && sampleRateHz != null && bitDepth != null) {
      return 'Dolby Atmos · $bitDepth-bit / ${(sampleRateHz! / 1000).toStringAsFixed(sampleRateHz! % 1000 == 0 ? 0 : 1)} kHz $codec$br';
    }
    if (isDolbyAtmos) return 'Dolby Atmos Spatial Audio$br';
    if (isHiRes && sampleRateHz != null && bitDepth != null) {
      return 'Hi-Res · $bitDepth-bit / ${(sampleRateHz! / 1000).toStringAsFixed(sampleRateHz! % 1000 == 0 ? 0 : 1)} kHz $codec$br';
    }
    if (isLossless) {
      final sr = sampleRateHz != null ? '${(sampleRateHz! / 1000).toStringAsFixed(1)} kHz' : '44.1 kHz';
      final bd = bitDepth != null ? '$bitDepth-bit' : '16-bit';
      return 'CD Lossless · $bd / $sr $codec$br';
    }
    if (bitrateKbps != null) {
      return 'High Fidelity · $bitrateKbps kbps $codec';
    }
    return '$codec Standard';
  }

  String get compactBadge {
    if (isDolbyAtmos && isHiRes) return 'ATMOS · ${bitrateKbps ?? 9216}k';
    if (isDolbyAtmos) return 'ATMOS · ${bitrateKbps ?? 768}k';
    if (isHiRes) return 'HI-RES · ${bitrateKbps ?? 4608}k';
    if (isLossless) return 'LOSSLESS · ${bitrateKbps ?? 1411}k';
    if (bitrateKbps != null) return '${bitrateKbps}k';
    return 'AUDIO';
  }
}

/// A resolved audio stream ready for playback.
class ResolvedStream {
  final String trackId;
  final String url;
  final String negotiatedQuality;
  final AudioMetadata metadata;
  final Map<String, String> headers;
  final String sourceId;
  final String sourceName;
  final bool isDASH;
  final bool isHLS;

  const ResolvedStream({
    required this.trackId,
    required this.url,
    required this.negotiatedQuality,
    required this.metadata,
    this.headers = const {},
    required this.sourceId,
    required this.sourceName,
    this.isDASH = false,
    this.isHLS = false,
  });
}
