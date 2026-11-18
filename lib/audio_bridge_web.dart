import 'dart:js_interop';

@JS('AuraBeatAudio')
external _AuraBeatAudioJs? get _auraBeatAudio;

@JS()
@staticInterop
class _AuraBeatAudioJs {}

extension _AuraBeatAudioJsExtension on _AuraBeatAudioJs {
  external void init();
  external void play(String title, [String? url]);
  external void pause();
  external void setSpatial(bool enabled, double width, double depth, double intensity);
  external void setVolume(double volume);
  external void setBassBoost(bool enabled, double gainDb);
  external void setSubBass(bool enabled, double gainDb);
  external void setSubBassEnhancement(bool enabled, double intensity, double frequencyHz, double outputLevelDb, String preset);
  external void setEqBand(int index, double gainDb);
}

class WebAudioBridge {
  static void init() {
    try {
      _auraBeatAudio?.init();
    } catch (_) {}
  }

  static void play(String title, [String? url, double sampleRate = 192000.0]) {
    try {
      if (url != null) {
        _auraBeatAudio?.play(title, url);
      } else {
        _auraBeatAudio?.play(title);
      }
    } catch (_) {}
  }

  static void pause() {
    try {
      _auraBeatAudio?.pause();
    } catch (_) {}
  }

  static void stop() {
    try {
      _auraBeatAudio?.pause();
    } catch (_) {}
  }

  static void setSpatialAudio(bool enabled) {
    try {
      _auraBeatAudio?.setSpatial(enabled, 2.5, 0.0, 0.0);
    } catch (_) {}
  }

  static void setSpatial(bool enabled, [double width = 2.5, double depth = 0.0, double intensity = 0.0]) {
    setSpatialAudio(enabled);
  }

  static void setVolume(double volume) {
    try {
      _auraBeatAudio?.setVolume(volume);
    } catch (_) {}
  }

  static void setBassBoost(bool enabled, [double gainDb = 14.0]) {
    try {
      _auraBeatAudio?.setBassBoost(enabled, gainDb);
    } catch (_) {}
  }

  static void setSubBass(bool enabled, [double gainDb = 14.0]) {
    try {
      _auraBeatAudio?.setSubBass(enabled, gainDb);
    } catch (_) {}
  }

  static void setSubBassEnhancement({
    required bool enabled,
    required double intensity,
    required double frequencyHz,
    required double outputLevelDb,
    required String preset,
  }) {
    try {
      _auraBeatAudio?.setSubBassEnhancement(enabled, intensity, frequencyHz, outputLevelDb, preset);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getSubBassConfiguration() async {
    return null;
  }

  static void resetSubBassConfiguration() {}

  static void setEqBand(int index, double gainDb) {
    try {
      _auraBeatAudio?.setEqBand(index, gainDb);
    } catch (_) {}
  }

  static void setEqualizer(List<double> bands) {
    try {
      for (int i = 0; i < bands.length; i++) {
        _auraBeatAudio?.setEqBand(i, bands[i]);
      }
    } catch (_) {}
  }

  static void setEqualizerMode(String mode) {}

  static void setTonePad(int x, int y, {bool focused = false}) {}

  static void setBalance(double balance) {}

  static void setPreset(String preset) {
    try {
      final clean = preset.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      const presetMap = <String, List<double>>{
        'flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'acoustic': [3.0, 1.5, 0.0, 1.5, 2.5, 2.0, 1.0],
        'bassboost': [6.0, 4.0, 1.5, 0.0, 0.0, 0.0, 0.0],
        'basscut': [-6.0, -4.0, -1.5, 0.0, 0.0, 0.0, 0.0],
        'vocal': [-3.0, -1.5, 1.0, 3.5, 3.0, 1.0, -1.0],
        'vocalclarity': [-3.0, -1.5, 1.0, 3.5, 3.0, 1.0, -1.0],
        'trebleboost': [0.0, 0.0, 0.0, 0.0, 1.5, 3.5, 5.0],
        'treblecut': [0.0, 0.0, 0.0, 0.0, -1.5, -3.5, -5.0],
        'loudness': [6.0, 3.5, 0.0, -1.5, -1.0, 2.0, 5.0],
        'spokenword': [-5.0, -2.5, 1.5, 4.0, 3.5, 1.5, -2.0],
        'electronic': [5.0, 3.0, -1.0, 0.0, 1.0, 3.0, 4.0],
        'rock': [4.0, 2.5, -1.0, -1.5, 1.0, 3.0, 3.5],
        'hiphop': [6.0, 4.0, 0.5, -1.0, 0.5, 2.0, 2.5],
        'jazz': [3.0, 1.5, 0.0, 1.0, 1.5, 2.0, 2.5],
        'classical': [3.0, 2.0, 0.0, 0.0, 1.0, 2.5, 3.0],
        'smallspeakers': [5.0, 4.0, 2.0, 0.5, 0.0, -1.0, -2.0],
        'latenight': [3.0, 1.0, 0.0, 1.5, 1.0, -1.0, -3.0],
        'audiophileclear': [4.5, 3.5, 1.0, 1.5, 2.0, 2.5, 3.0],
        'subbass': [6.0, 4.5, 1.5, 0.5, 1.0, 1.5, 2.0],
        'aurasignature': [3.0, 2.0, 1.5, 1.0, 1.5, 2.0, 2.5],
      };
      final bands = presetMap[clean];
      if (bands != null) {
        setEqualizer(bands);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getDSPConfiguration() async => null;

  static Future<Map<String, dynamic>?> getDSPDiagnostics() async => null;

  static void setPlaybackSpeed(double speed) {}

  static void setSilenceSkipping(bool enabled) {}

  static Future<void> setModernHlsTapEnabled(bool enabled) async {}

  static Future<bool> isModernHlsTapEnabled() async => false;

  static Future<Map<String, dynamic>?> getPipelineTelemetry() async => null;
}
