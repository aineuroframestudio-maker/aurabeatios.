import 'package:flutter/services.dart';

class WebAudioBridge {
  static const MethodChannel _channel = MethodChannel('com.aurabeat.audio/quality');

  static void init() {
    try {
      _channel.invokeMethod('init').catchError((_) {});
    } catch (_) {}
  }

  static void play(String title, [String? url, double sampleRate = 192000.0]) {
    try {
      _channel.invokeMethod('play', {
        'title': title,
        'url': url,
        'sampleRate': sampleRate,
      }).catchError((_) {});
    } catch (_) {}
  }

  static void pause() {
    try {
      _channel.invokeMethod('pause').catchError((_) {});
    } catch (_) {}
  }

  static void stop() {
    try {
      _channel.invokeMethod('stop').catchError((_) {});
    } catch (_) {}
  }

  /// Sets Desktop Spatial Audio state (matching BitChord Desktop: playbackEngine.setSpatialAudio).
  static void setSpatialAudio(bool enabled) {
    try {
      _channel.invokeMethod('setSpatialAudio', enabled).catchError((_) {});
    } catch (_) {}
  }

  /// Backward-compatible alias for setSpatialAudio.
  static void setSpatial(bool enabled, [double width = 2.5, double depth = 0.0, double intensity = 0.0]) {
    setSpatialAudio(enabled);
  }

  static void setVolume(double volume) {
    try {
      _channel.invokeMethod('setVolume', volume).catchError((_) {});
    } catch (_) {}
  }

  static void setBassBoost(bool enabled, [double gainDb = 14.0]) {
    try {
      _channel.invokeMethod('setBassBoost', {
        'enabled': enabled,
        'gainDb': gainDb,
      }).catchError((_) {});
    } catch (_) {}
  }

  static void setSubBass(bool enabled, [double gainDb = 14.0]) {
    setBassBoost(enabled, gainDb);
  }

  static void setSubBassEnhancement({
    required bool enabled,
    required double intensity,
    required double frequencyHz,
    required double outputLevelDb,
    required String preset,
  }) {
    try {
      _channel.invokeMethod('setSubBassEnhancement', {
        'enabled': enabled,
        'intensity': intensity,
        'frequencyHz': frequencyHz,
        'outputLevelDb': outputLevelDb,
        'preset': preset,
      }).catchError((_) {});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getSubBassConfiguration() async {
    try {
      final res = await _channel.invokeMethod('getSubBassConfiguration');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return null;
  }

  static void resetSubBassConfiguration() {
    try {
      _channel.invokeMethod('resetSubBassConfiguration').catchError((_) {});
    } catch (_) {}
  }

  static void setEqBand(int index, double gainDb) {
    try {
      _channel.invokeMethod('setEqBand', {
        'index': index,
        'gainDb': gainDb,
      }).catchError((_) {});
    } catch (_) {}
  }

  static void setEqualizer(List<double> bands) {
    try {
      _channel.invokeMethod('setEqualizer', bands).catchError((_) {});
    } catch (_) {}
  }

  static void setEqualizerMode(String mode) {
    try {
      _channel.invokeMethod('setEqualizerMode', mode).catchError((_) {});
    } catch (_) {}
  }

  static void setTonePad(int x, int y, {bool focused = false}) {
    try {
      _channel.invokeMethod('setTonePad', {
        'x': x,
        'y': y,
        'focused': focused,
      }).catchError((_) {});
    } catch (_) {}
  }

  static void setBalance(double balance) {
    try {
      _channel.invokeMethod('setBalance', balance).catchError((_) {});
    } catch (_) {}
  }

  static void setPreset(String preset) {
    try {
      _channel.invokeMethod('setPreset', preset).catchError((_) {});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getDSPConfiguration() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getDSPConfiguration');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDSPDiagnostics() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getDSPDiagnostics');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOptimalQuality() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getOptimalQuality');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getNetworkStatus() async {
    try {
      final res = await _channel.invokeMethod<String>('getNetworkStatus');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setQualityPreference(int qualityId) async {
    try {
      await _channel.invokeMethod('setQualityPreference', qualityId);
    } catch (_) {}
  }

  static Future<int?> getQualityPreference() async {
    try {
      final res = await _channel.invokeMethod<int>('getQualityPreference');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setArtistQualityOverride(String artistId, int qualityId) async {
    try {
      await _channel.invokeMethod('setArtistQualityOverride', {
        'artistId': artistId,
        'quality': qualityId,
      });
    } catch (_) {}
  }

  static Future<int?> getArtistQualityOverride(String artistId) async {
    try {
      final res = await _channel.invokeMethod<int>('getArtistQualityOverride', artistId);
      return res;
    } catch (_) {
      return null;
    }
  }

  static void setPlaybackSpeed(double speed) {
    try {
      _channel.invokeMethod('setPlaybackSpeed', speed).catchError((_) {});
    } catch (_) {}
  }

  static void setSilenceSkipping(bool enabled) {
    try {
      _channel.invokeMethod('setSilenceSkipping', enabled).catchError((_) {});
    } catch (_) {}
  }

  static Future<void> setModernHlsTapEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setModernHlsTapEnabled', enabled);
    } catch (_) {}
  }

  static Future<bool> isModernHlsTapEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isModernHlsTapEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPipelineTelemetry() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getPipelineTelemetry');
      return res;
    } catch (_) {
      return null;
    }
  }
}
