// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord Desktop audio engine (Audio Pipeline Telemetry Snapshot).

/// Immutable snapshot of the playback signal chain across decoding, DSP, and hardware sink stages.
class AudioPipelineTelemetry {
  final String? sourceFormat;
  final String? decoderName;
  final int? decodedSampleRateHz;
  final int? decodedChannels;
  final int? outputSampleRateHz;
  final int? outputChannels;
  final bool? outputIsFloat;
  final int? outputBytesPerSample;
  final String? deviceName;
  final int bufferBytes;
  final bool equalizerEnabled;
  final bool skipSilence;
  final double playbackSpeed;
  final bool spatialEnabled;
  final bool realtimeTapActive;
  final double preampAttenuationDb;
  final int tapCallbackCount;
  final int processedFrames;
  final bool isHlsStream;
  final bool isFairPlayStream;
  final bool modernHlsTapEnabled;
  final bool iosSpatialProcessorAttached;
  final bool iosSpatialProcessorEnabled;
  final bool iosSpatialProcessorActive;
  final int iosSpatialCallbackCount;
  final int iosSpatialProcessedFrames;
  final String iosSpatialBypassReason;
  final int iosSpatialInputSampleRate;
  final int iosSpatialInputChannels;
  final String iosSpatialLastProcessingError;
  final bool dolbyCodecDetected;
  final bool dolbyJocManifestDetected;
  final bool dolbyJocMetadataVerified;
  final bool dolbyBitstreamVerified;
  final bool dolbyNativePlaybackActive;
  final bool dolbySpatialPlaybackAvailable;
  final bool dolbyAppDspBypassed;
  final String dolbyFallbackReason;
  final String dolbyOutputRoute;
  final String dolbyInputCodec;
  final double dolbyInputSampleRate;
  final String dolbyInputChannelLayout;
  final String dolbyRenderingVerificationStatus;

  const AudioPipelineTelemetry({
    this.sourceFormat,
    this.decoderName,
    this.decodedSampleRateHz,
    this.decodedChannels,
    this.outputSampleRateHz,
    this.outputChannels,
    this.outputIsFloat,
    this.outputBytesPerSample,
    this.deviceName,
    this.bufferBytes = 0,
    this.equalizerEnabled = false,
    this.skipSilence = false,
    this.playbackSpeed = 1.0,
    this.spatialEnabled = false,
    this.realtimeTapActive = false,
    this.preampAttenuationDb = 0.0,
    this.tapCallbackCount = 0,
    this.processedFrames = 0,
    this.isHlsStream = false,
    this.isFairPlayStream = false,
    this.modernHlsTapEnabled = false,
    this.iosSpatialProcessorAttached = false,
    this.iosSpatialProcessorEnabled = false,
    this.iosSpatialProcessorActive = false,
    this.iosSpatialCallbackCount = 0,
    this.iosSpatialProcessedFrames = 0,
    this.iosSpatialBypassReason = 'No Audio Tap Attached',
    this.iosSpatialInputSampleRate = 44100,
    this.iosSpatialInputChannels = 2,
    this.iosSpatialLastProcessingError = 'None',
    this.dolbyCodecDetected = false,
    this.dolbyJocManifestDetected = false,
    this.dolbyJocMetadataVerified = false,
    this.dolbyBitstreamVerified = false,
    this.dolbyNativePlaybackActive = false,
    this.dolbySpatialPlaybackAvailable = false,
    this.dolbyAppDspBypassed = false,
    this.dolbyFallbackReason = 'UNKNOWN',
    this.dolbyOutputRoute = 'UNKNOWN',
    this.dolbyInputCodec = 'UNKNOWN',
    this.dolbyInputSampleRate = 0.0,
    this.dolbyInputChannelLayout = 'UNKNOWN',
    this.dolbyRenderingVerificationStatus = 'UNKNOWN',
  });

  /// Whether the decoded stream must be resampled to match output device capabilities.
  bool get resampling =>
      decodedSampleRateHz != null &&
      outputSampleRateHz != null &&
      decodedSampleRateHz != outputSampleRateHz;

  /// Human-friendly display label for the active decoder.
  String get decoderLabel {
    if (decoderName == null) return 'Unknown';
    switch (decoderName!.toLowerCase()) {
      case 'flac':
        return 'FLAC Lossless';
      case 'alac':
        return 'Apple Lossless (ALAC)';
      case 'pcm':
      case 'wav':
        return 'Linear PCM';
      case 'aac':
        return 'AAC-LC';
      case 'mp3':
        return 'MPEG Layer 3 (MP3)';
      case 'opus':
        return 'Opus Interactive';
      case 'eac3':
      case 'eac3-joc':
        return 'Dolby Atmos (E-AC-3 JOC)';
      default:
        return decoderName!.toUpperCase();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceFormat': sourceFormat,
      'decoderName': decoderName,
      'decoderLabel': decoderLabel,
      'decodedSampleRateHz': decodedSampleRateHz,
      'decodedChannels': decodedChannels,
      'outputSampleRateHz': outputSampleRateHz,
      'outputChannels': outputChannels,
      'outputIsFloat': outputIsFloat,
      'outputBytesPerSample': outputBytesPerSample,
      'deviceName': deviceName,
      'bufferBytes': bufferBytes,
      'resampling': resampling,
      'equalizerEnabled': equalizerEnabled,
      'skipSilence': skipSilence,
      'playbackSpeed': playbackSpeed,
      'spatialEnabled': spatialEnabled,
      'realtimeTapActive': realtimeTapActive,
      'preampAttenuationDb': preampAttenuationDb,
      'tapCallbackCount': tapCallbackCount,
      'processedFrames': processedFrames,
      'isHlsStream': isHlsStream,
      'isFairPlayStream': isFairPlayStream,
      'modernHlsTapEnabled': modernHlsTapEnabled,
      'iosSpatialProcessorAttached': iosSpatialProcessorAttached,
      'iosSpatialProcessorEnabled': iosSpatialProcessorEnabled,
      'iosSpatialProcessorActive': iosSpatialProcessorActive,
      'iosSpatialCallbackCount': iosSpatialCallbackCount,
      'iosSpatialProcessedFrames': iosSpatialProcessedFrames,
      'iosSpatialBypassReason': iosSpatialBypassReason,
      'iosSpatialInputSampleRate': iosSpatialInputSampleRate,
      'iosSpatialInputChannels': iosSpatialInputChannels,
      'iosSpatialLastProcessingError': iosSpatialLastProcessingError,
      'dolbyCodecDetected': dolbyCodecDetected,
      'dolbyJocManifestDetected': dolbyJocManifestDetected,
      'dolbyJocMetadataVerified': dolbyJocMetadataVerified,
      'dolbyBitstreamVerified': dolbyBitstreamVerified,
      'dolbyNativePlaybackActive': dolbyNativePlaybackActive,
      'dolbySpatialPlaybackAvailable': dolbySpatialPlaybackAvailable,
      'dolbyAppDspBypassed': dolbyAppDspBypassed,
      'dolbyFallbackReason': dolbyFallbackReason,
      'dolbyOutputRoute': dolbyOutputRoute,
      'dolbyInputCodec': dolbyInputCodec,
      'dolbyInputSampleRate': dolbyInputSampleRate,
      'dolbyInputChannelLayout': dolbyInputChannelLayout,
      'dolbyRenderingVerificationStatus': dolbyRenderingVerificationStatus,
    };
  }

  factory AudioPipelineTelemetry.fromMap(Map<String, dynamic> map) {
    return AudioPipelineTelemetry(
      sourceFormat: map['sourceFormat'] as String?,
      decoderName: map['decoderName'] as String?,
      decodedSampleRateHz: map['decodedSampleRateHz'] as int?,
      decodedChannels: map['decodedChannels'] as int?,
      outputSampleRateHz: map['outputSampleRateHz'] as int?,
      outputChannels: map['outputChannels'] as int?,
      outputIsFloat: map['outputIsFloat'] as bool?,
      outputBytesPerSample: map['outputBytesPerSample'] as int?,
      deviceName: map['deviceName'] as String?,
      bufferBytes: (map['bufferBytes'] as num?)?.toInt() ?? 0,
      equalizerEnabled: map['equalizerEnabled'] as bool? ?? false,
      skipSilence: map['skipSilence'] as bool? ?? false,
      playbackSpeed: (map['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      spatialEnabled: map['spatialEnabled'] as bool? ?? false,
      realtimeTapActive: map['realtimeTapActive'] as bool? ?? false,
      preampAttenuationDb: (map['preampAttenuationDb'] as num?)?.toDouble() ?? 0.0,
      tapCallbackCount: (map['tapCallbackCount'] as num?)?.toInt() ?? 0,
      processedFrames: (map['processedFrames'] as num?)?.toInt() ?? 0,
      isHlsStream: map['isHlsStream'] as bool? ?? false,
      isFairPlayStream: map['isFairPlayStream'] as bool? ?? false,
      modernHlsTapEnabled: map['modernHlsTapEnabled'] as bool? ?? false,
      iosSpatialProcessorAttached: map['iosSpatialProcessorAttached'] as bool? ?? false,
      iosSpatialProcessorEnabled: map['iosSpatialProcessorEnabled'] as bool? ?? false,
      iosSpatialProcessorActive: map['iosSpatialProcessorActive'] as bool? ?? false,
      iosSpatialCallbackCount: (map['iosSpatialCallbackCount'] as num?)?.toInt() ?? 0,
      iosSpatialProcessedFrames: (map['iosSpatialProcessedFrames'] as num?)?.toInt() ?? 0,
      iosSpatialBypassReason: map['iosSpatialBypassReason'] as String? ?? 'No Audio Tap Attached',
      iosSpatialInputSampleRate: (map['iosSpatialInputSampleRate'] as num?)?.toInt() ?? 44100,
      iosSpatialInputChannels: (map['iosSpatialInputChannels'] as num?)?.toInt() ?? 2,
      iosSpatialLastProcessingError: map['iosSpatialLastProcessingError'] as String? ?? 'None',
      dolbyCodecDetected: map['dolbyCodecDetected'] as bool? ?? false,
      dolbyJocManifestDetected: map['dolbyJocManifestDetected'] as bool? ?? false,
      dolbyJocMetadataVerified: map['dolbyJocMetadataVerified'] as bool? ?? false,
      dolbyBitstreamVerified: map['dolbyBitstreamVerified'] as bool? ?? false,
      dolbyNativePlaybackActive: map['dolbyNativePlaybackActive'] as bool? ?? false,
      dolbySpatialPlaybackAvailable: map['dolbySpatialPlaybackAvailable'] as bool? ?? false,
      dolbyAppDspBypassed: map['dolbyAppDspBypassed'] as bool? ?? false,
      dolbyFallbackReason: map['dolbyFallbackReason'] as String? ?? 'UNKNOWN',
      dolbyOutputRoute: map['dolbyOutputRoute'] as String? ?? 'UNKNOWN',
      dolbyInputCodec: map['dolbyInputCodec'] as String? ?? 'UNKNOWN',
      dolbyInputSampleRate: (map['dolbyInputSampleRate'] as num?)?.toDouble() ?? 0.0,
      dolbyInputChannelLayout: map['dolbyInputChannelLayout'] as String? ?? 'UNKNOWN',
      dolbyRenderingVerificationStatus: map['dolbyRenderingVerificationStatus'] as String? ?? 'UNKNOWN',
    );
  }
}
