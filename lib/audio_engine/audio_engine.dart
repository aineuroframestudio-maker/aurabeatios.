// Copyright (C) 2026 AuraBeat Project.
// Unified Audio Engine Architecture uniting Output Negotiation,
// PCM boundary layer, and native BitChord 1.0.8 audio engine delegation.
// All audio processing, decoding, dynamic EQ, and spatial rendering are
// executed exclusively in the native BitChord 1.0.8 Rust + Swift engine.

import '../audio_bridge.dart';
import 'negotiator/output_negotiator.dart';
import 'sub_bass/sub_bass_engine.dart';

export 'pcm/pcm_encoding.dart';
export 'pcm/audio_block.dart';
export 'pcm/pcm_boundary.dart';
export 'pipeline/audio_pipeline_telemetry.dart';
export 'buffer/decode_ahead_buffer.dart';
export 'negotiator/output_negotiator.dart';
export 'dsd/dsd_format.dart';
export 'sub_bass/sub_bass_config.dart';
export 'sub_bass/sub_bass_dsp.dart';
export 'sub_bass/sub_bass_engine.dart';

/// Lightweight representation of EQ Curve parameters and anti-clipping headroom.
class EqCurve {
  final List<double> gainsDb;
  final double preampDb;

  const EqCurve({required this.gainsDb, required this.preampDb});

  static const EqCurve flat = EqCurve(
    gainsDb: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    preampDb: 0.0,
  );
}

/// Computes manual EQ curve and anti-clipping preamp attenuation.
EqCurve manualCurve(List<double> bandsDb) {
  double maxBoost = 0.0;
  for (final b in bandsDb) {
    if (b > maxBoost) maxBoost = b;
  }
  final preamp = maxBoost > 0.0 ? -maxBoost : 0.0;
  return EqCurve(gainsDb: List.unmodifiable(bandsDb), preampDb: preamp);
}

/// Computes tone pad tilt curve.
EqCurve toneCurve(int x, int y, {bool focused = false}) {
  final clampedX = x.clamp(-5, 5).toDouble();
  final clampedY = y.clamp(-5, 5).toDouble();
  final lowGain = -clampedX * 1.5;
  final highGain = clampedX * 1.5;
  final midGain = clampedY * 1.5;
  final bands = [lowGain, lowGain * 0.5, midGain, midGain, midGain * 0.5, highGain * 0.5, highGain];
  return manualCurve(bands);
}

/// Master Audio Engine facade for AuraBeat.
/// Directly bridges all playback, equalization, spatial audio, and DSP parameters
/// to the BitChord 1.0.8 native core engine without duplicate Dart-level processing.
class AuraBeatAudioEngine {
  static final AuraBeatAudioEngine instance = AuraBeatAudioEngine._internal();

  /// Temporary bypass flag for Phase 5 original playback verification.
  /// Preserves all spatial features and settings, but disables spatial DSP rendering
  /// during verification so that original audio is unmodified.
  static bool bypassSpatialAudio = true;

  bool _spatialAudioEnabled = false;
  List<double> _manualBands = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  double _playbackSpeed = 1.0;
  bool _silenceSkippingEnabled = false;
  double _balance = 0.0;
  String _activePreset = 'Flat';
  OutputNegotiationResult? _lastNegotiationResult;

  AuraBeatAudioEngine._internal();

  SubBassEngine get subBass => SubBassEngine.instance;

  bool get isSpatialAudioEnabled => _spatialAudioEnabled;
  List<double> get manualBands => List.unmodifiable(_manualBands);
  double get playbackSpeed => _playbackSpeed;
  bool get isSilenceSkippingEnabled => _silenceSkippingEnabled;
  double get balance => _balance;
  String get activePreset => _activePreset;
  OutputNegotiationResult? get lastNegotiationResult => _lastNegotiationResult;

  /// Applies an equalizer preset and syncs with native BitChord 1.0.8 engine.
  void applyPreset(String preset) {
    _activePreset = preset;
    WebAudioBridge.setPreset(preset);
  }

  /// Sets custom manual 7-band slider values and syncs to native BitChord 1.0.8 dynamic EQ.
  void setManualBands(List<double> bandsDb) {
    _manualBands = List<double>.from(bandsDb);
    WebAudioBridge.setEqualizer(_manualBands);
  }

  /// Sets tone pad coordinate with warm/bright tilt and scoop/push contour.
  void setTonePad(int x, int y, {bool focused = false}) {
    WebAudioBridge.setTonePad(x, y, focused: focused);
  }

  /// Sets stereo balance trim (-1.0 to +1.0).
  void setBalance(double balance) {
    _balance = balance;
    WebAudioBridge.setBalance(balance);
  }

  /// Sets Spatial Audio state (delegated directly to BitChord 1.0.8 PlayerEngine and HeadTracker).
  /// Respects temporary Phase 5 bypass during playback verification.
  void setSpatialAudio(bool enabled) {
    _spatialAudioEnabled = enabled;
    final effective = bypassSpatialAudio ? false : enabled;
    WebAudioBridge.setSpatialAudio(effective);
  }

  /// Backward-compatible alias for setSpatialAudio.
  void setStereoWidening(bool enabled) {
    setSpatialAudio(enabled);
  }

  /// Sets playback speed using pitch-preserving WSOLA time stretching in native-core (0.25x - 3.0x).
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    WebAudioBridge.setPlaybackSpeed(speed);
  }

  /// Enables or disables dynamic silence skipping in native-core.
  void setSilenceSkipping(bool enabled) {
    _silenceSkippingEnabled = enabled;
    WebAudioBridge.setSilenceSkipping(enabled);
  }

  /// Resets internal state.
  void reset() {
    _spatialAudioEnabled = false;
    _manualBands = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _playbackSpeed = 1.0;
    _silenceSkippingEnabled = false;
    _balance = 0.0;
    _activePreset = 'Flat';
  }

  /// Negotiates audio pipeline output for a track and hardware route.
  OutputNegotiationResult negotiate({
    required SourceDescriptor source,
    required RouteDescriptor route,
    String decoderName = 'AuraBeat BitChord 1.0.8 CoreAudio Lossless',
  }) {
    final result = OutputNegotiator.negotiate(
      source: source,
      route: route,
      decoderName: decoderName,
      isEqActive: _manualBands.any((b) => b != 0.0),
      preampDb: 0.0,
    );
    _lastNegotiationResult = result;
    return result;
  }
}
