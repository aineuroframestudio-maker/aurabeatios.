// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord audio engine (Apache License 2.0).

import 'dart:math' as math;
import '../pcm/pcm_encoding.dart';

/// Output transport mechanism selected by the universal best-path audio engine.
enum OutputTransport {
  coreAudio(label: 'Apple AVFoundation CoreAudio'),
  audioTrackDirect(label: 'Android AudioTrack (Direct / Offload)'),
  audioTrackStandard(label: 'Android AudioTrack (System Mixer)'),
  directUsb(label: 'Direct USB Audio Class 2.0'),
  webAudio(label: 'W3C WebAudio AudioContext');

  final String label;
  const OutputTransport({required this.label});
}

/// Authoritative rationale when the audio pipeline falls back from the source's
/// native rate, bit depth, or direct transport to a lower-precision or system-mixed path.
enum FallbackReason {
  none(label: 'None (Direct / Bit-Perfect Path)'),
  unsupportedFormat(label: 'Unsupported source format on current platform'),
  routeLimitation(label: 'Route limitation (output device capability profile)'),
  osLimitation(label: 'OS limitation (system audio policy downmix/SRC)'),
  directUsbUnavailable(label: 'Direct USB DAC stream unavailable'),
  decoderLimitation(label: 'Decoder limitation (downmixed before output)');

  final String label;
  const FallbackReason({required this.label});
}

/// Layer 1: Source File / Stream Audio Characteristics.
class SourceDescriptor {
  final String codec; // e.g., 'FLAC', 'ALAC', 'WAV', 'E-AC-3 JOC', 'AAC', 'DSD'
  final int sampleRateHz;
  final int channelCount;
  final int? bitDepth;
  final int? bitrateKbps;

  const SourceDescriptor({
    required this.codec,
    required this.sampleRateHz,
    required this.channelCount,
    this.bitDepth,
    this.bitrateKbps,
  });

  bool get isHiRes => sampleRateHz > 48000 || (bitDepth != null && bitDepth! > 16);
  bool get isLossless => codec.toUpperCase().contains('FLAC') ||
      codec.toUpperCase().contains('ALAC') ||
      codec.toUpperCase().contains('WAV') ||
      codec.toUpperCase().contains('DSD');
}

/// Layer 2: Decoder Engine State.
class DecoderDescriptor {
  final String name; // e.g. 'AVFoundation', 'ExoPlayer', 'WebAudio'
  final String encoding; // canonical 'Float32'
  final int sampleRateHz;
  final int channelCount;

  const DecoderDescriptor({
    required this.name,
    this.encoding = 'Float32',
    required this.sampleRateHz,
    required this.channelCount,
  });
}

/// Layer 3: DSP Pipeline Stage.
class DspDescriptor {
  final String format; // canonical 'Float32'
  final int sampleRateHz;
  final int channelCount;
  final double preampAttenuationDb;
  final bool eqActive;
  final bool spatialActive;

  const DspDescriptor({
    this.format = 'Float32',
    required this.sampleRateHz,
    required this.channelCount,
    this.preampAttenuationDb = 0.0,
    this.eqActive = false,
    this.spatialActive = false,
  });
}

/// Route kind classification.
enum AudioRouteKind {
  builtInSpeaker,
  headphones,
  bluetoothA2dp,
  airPlay,
  usbDac,
  hdmi,
  unknown,
}

/// Layer 4: Output Hardware Route.
class RouteDescriptor {
  final AudioRouteKind kind;
  final String deviceName;
  final bool isDirectCapable;
  final List<int> advertisedSampleRates;
  final List<int> advertisedBitDepths;
  final bool isSpatialAudioEnabled;
  final String? bluetoothCodec;

  const RouteDescriptor({
    required this.kind,
    required this.deviceName,
    this.isDirectCapable = false,
    this.advertisedSampleRates = const [44100, 48000],
    this.advertisedBitDepths = const [16],
    this.isSpatialAudioEnabled = false,
    this.bluetoothCodec,
  });
}

/// Layer 5: Output Sink Configuration.
class OutputDescriptor {
  final OutputTransport transport;
  final PcmEncoding encoding;
  final int sampleRateHz;
  final int channelCount;
  final bool isDirect;
  final int? systemMixerRateHz;
  final FallbackReason fallbackReason;
  final String? fallbackDetail;

  const OutputDescriptor({
    required this.transport,
    required this.encoding,
    required this.sampleRateHz,
    required this.channelCount,
    this.isDirect = false,
    this.systemMixerRateHz,
    this.fallbackReason = FallbackReason.none,
    this.fallbackDetail,
  });
}

/// Authoritative snapshot of the 6-layer audio pipeline state:
/// Source -> Decoder -> DSP -> Route -> Output -> System.
class OutputNegotiationResult {
  final SourceDescriptor source;
  final DecoderDescriptor decoder;
  final DspDescriptor dsp;
  final RouteDescriptor route;
  final OutputDescriptor output;

  const OutputNegotiationResult({
    required this.source,
    required this.decoder,
    required this.dsp,
    required this.route,
    required this.output,
  });

  /// True if source sample rate was preserved end-to-end without downstream mixer sample-rate conversion (SRC).
  bool get isSampleRatePreserved {
    if (output.isDirect) return true;
    if (output.systemMixerRateHz == null) return output.sampleRateHz == source.sampleRateHz;
    return output.sampleRateHz == output.systemMixerRateHz && output.sampleRateHz == source.sampleRateHz;
  }

  /// True if source bit depth was preserved without truncation.
  bool get isBitDepthPreserved {
    final srcDepth = source.bitDepth ?? 16;
    return output.encoding.bitsPerSample >= srcDepth;
  }

  /// True if the audio chain achieves bit-perfect pass-through.
  bool get isBitPerfect {
    return isSampleRatePreserved &&
        isBitDepthPreserved &&
        output.isDirect &&
        !dsp.eqActive &&
        dsp.preampAttenuationDb == 0.0;
  }
}

/// Universal Best-Path Output Negotiation Engine.
///
/// Deterministic selection order:
/// 1. Direct hardware / USB DAC pass-through when route supports the exact format, rate, and bit depth.
/// 2. Native high-res AVFoundation / AudioTrack output.
/// 3. Bluetooth A2DP bandwidth evaluation (e.g. LDAC 96kHz vs AAC/SBC 44.1/48kHz).
/// 4. Safe system downmix fallback with factual diagnostics.
class OutputNegotiator {
  static OutputNegotiationResult negotiate({
    required SourceDescriptor source,
    required RouteDescriptor route,
    String decoderName = 'AuraBeat CoreAudio / AVPlayer',
    bool isEqActive = false,
    double preampDb = 0.0,
    bool isSpatialDspActive = false,
    OutputTransport preferredTransport = OutputTransport.coreAudio,
  }) {
    final decoder = DecoderDescriptor(
      name: decoderName,
      encoding: 'Float32',
      sampleRateHz: source.sampleRateHz,
      channelCount: source.channelCount,
    );

    final dsp = DspDescriptor(
      format: 'Float32',
      sampleRateHz: source.sampleRateHz,
      channelCount: source.channelCount,
      preampAttenuationDb: preampDb,
      eqActive: isEqActive,
      spatialActive: isSpatialDspActive,
    );

    // Evaluate target sample rate, encoding, and transport based on route
    OutputTransport transport = preferredTransport;
    PcmEncoding encoding = PcmEncoding.pcm16;
    int targetSampleRate = source.sampleRateHz;
    int targetChannels = source.channelCount;
    bool isDirect = false;
    int? systemMixerRate;
    FallbackReason fallbackReason = FallbackReason.none;
    String? fallbackDetail;

    switch (route.kind) {
      case AudioRouteKind.usbDac:
      case AudioRouteKind.hdmi:
        // External High-Res DAC / HDMI Route
        final supportsRate = route.advertisedSampleRates.isEmpty ||
            route.advertisedSampleRates.contains(source.sampleRateHz);
        if (supportsRate && route.isDirectCapable) {
          isDirect = true;
          targetSampleRate = source.sampleRateHz;
          encoding = (source.bitDepth != null && source.bitDepth! > 16)
              ? PcmEncoding.pcm24Packed
              : PcmEncoding.pcm16;
          fallbackReason = FallbackReason.none;
        } else {
          isDirect = false;
          systemMixerRate = 48000;
          targetSampleRate = 48000;
          encoding = PcmEncoding.pcm16;
          fallbackReason = FallbackReason.routeLimitation;
          fallbackDetail = 'Route does not advertise native direct support for ${source.sampleRateHz} Hz';
        }
        break;

      case AudioRouteKind.bluetoothA2dp:
        // Bluetooth Wireless Route
        final codec = route.bluetoothCodec?.toUpperCase() ?? 'SBC';
        if (codec.contains('LDAC') && source.sampleRateHz >= 96000) {
          targetSampleRate = 96000;
          encoding = PcmEncoding.pcm24Packed;
          systemMixerRate = 96000;
          fallbackReason = FallbackReason.none;
        } else if (codec.contains('APTX HD')) {
          targetSampleRate = 48000;
          encoding = PcmEncoding.pcm24Packed;
          systemMixerRate = 48000;
          if (source.sampleRateHz > 48000) {
            fallbackReason = FallbackReason.routeLimitation;
            fallbackDetail = 'aptX HD is bandwidth-capped at 48 kHz / 24-bit';
          }
        } else {
          // AAC / SBC
          targetSampleRate = 44100;
          encoding = PcmEncoding.pcm16;
          systemMixerRate = 44100;
          if (source.sampleRateHz > 44100 || (source.bitDepth != null && source.bitDepth! > 16)) {
            fallbackReason = FallbackReason.routeLimitation;
            fallbackDetail = 'Standard Bluetooth ($codec) downsamples to 44.1 kHz / 16-bit';
          }
        }
        break;

      case AudioRouteKind.builtInSpeaker:
        // Built-in Phone Speaker: safely capped to 48kHz 16-bit
        targetSampleRate = math.min(source.sampleRateHz, 48000);
        targetChannels = math.min(source.channelCount, 2);
        encoding = PcmEncoding.pcm16;
        systemMixerRate = 48000;
        if (source.sampleRateHz > 48000 || (source.bitDepth != null && source.bitDepth! > 16)) {
          fallbackReason = FallbackReason.osLimitation;
          fallbackDetail = 'Built-in speakers clamped to 48 kHz / 16-bit PCM for hardware protection';
        }
        break;

      case AudioRouteKind.headphones:
      case AudioRouteKind.airPlay:
      case AudioRouteKind.unknown:
        // Wired headphones / AirPlay / General output
        final maxRate = route.advertisedSampleRates.isEmpty
            ? 48000
            : route.advertisedSampleRates.reduce(math.max);
        targetSampleRate = math.min(source.sampleRateHz, maxRate);
        encoding = (source.bitDepth != null && source.bitDepth! > 16 && route.advertisedBitDepths.contains(24))
            ? PcmEncoding.pcm24Packed
            : PcmEncoding.pcm16;
        systemMixerRate = 48000;
        if (source.sampleRateHz > targetSampleRate) {
          fallbackReason = FallbackReason.routeLimitation;
          fallbackDetail = 'Downsampled from ${source.sampleRateHz} Hz to $targetSampleRate Hz matching device ceiling';
        }
        break;
    }

    final output = OutputDescriptor(
      transport: transport,
      encoding: encoding,
      sampleRateHz: targetSampleRate,
      channelCount: targetChannels,
      isDirect: isDirect,
      systemMixerRateHz: systemMixerRate,
      fallbackReason: fallbackReason,
      fallbackDetail: fallbackDetail,
    );

    return OutputNegotiationResult(
      source: source,
      decoder: decoder,
      dsp: dsp,
      route: route,
      output: output,
    );
  }
}
