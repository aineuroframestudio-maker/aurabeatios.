import 'package:flutter/services.dart';

class SettingsService {
  static const MethodChannel _channel = MethodChannel('com.aurabeat/settings');

  // Theme
  static Future<String> getThemeMode() async {
    try {
      return await _channel.invokeMethod<String>('getThemeMode') ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  static Future<void> setThemeMode(String mode) async {
    try {
      await _channel.invokeMethod('setThemeMode', mode);
    } catch (_) {}
  }

  // Language
  static Future<String> getLanguage() async {
    try {
      return await _channel.invokeMethod<String>('getLanguage') ?? 'en';
    } catch (_) {
      return 'en';
    }
  }

  static Future<void> setLanguage(String lang) async {
    try {
      await _channel.invokeMethod('setLanguage', lang);
    } catch (_) {}
  }

  // Audio Quality
  static Future<int> getAudioQuality() async {
    try {
      return await _channel.invokeMethod<int>('getAudioQuality') ?? 3;
    } catch (_) {
      return 3;
    }
  }

  static Future<void> setAudioQuality(int quality) async {
    try {
      await _channel.invokeMethod('setAudioQuality', quality);
    } catch (_) {}
  }

  // Gapless
  static Future<bool> getGapless() async {
    try {
      return await _channel.invokeMethod<bool>('getGapless') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setGapless(bool enabled) async {
    try {
      await _channel.invokeMethod('setGapless', enabled);
    } catch (_) {}
  }

  // Crossfade
  static Future<bool> getCrossfade() async {
    try {
      return await _channel.invokeMethod<bool>('getCrossfade') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setCrossfade(bool enabled) async {
    try {
      await _channel.invokeMethod('setCrossfade', enabled);
    } catch (_) {}
  }

  // ReplayGain
  static Future<bool> getReplayGain() async {
    try {
      return await _channel.invokeMethod<bool>('getReplayGain') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setReplayGain(bool enabled) async {
    try {
      await _channel.invokeMethod('setReplayGain', enabled);
    } catch (_) {}
  }

  // Volume Normalization
  static Future<bool> getVolumeNormalization() async {
    try {
      return await _channel.invokeMethod<bool>('getVolumeNormalization') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setVolumeNormalization(bool enabled) async {
    try {
      await _channel.invokeMethod('setVolumeNormalization', enabled);
    } catch (_) {}
  }

  // Background Playback
  static Future<bool> getBackgroundPlayback() async {
    try {
      return await _channel.invokeMethod<bool>('getBackgroundPlayback') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setBackgroundPlayback(bool enabled) async {
    try {
      await _channel.invokeMethod('setBackgroundPlayback', enabled);
    } catch (_) {}
  }

  // Equalizer
  static Future<bool> getEqEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('getEqEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEqEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEqEnabled', enabled);
    } catch (_) {}
  }

  static Future<String> getEqPreset() async {
    try {
      return await _channel.invokeMethod<String>('getEqPreset') ?? 'Flat';
    } catch (_) {
      return 'Flat';
    }
  }

  static Future<void> setEqPreset(String preset) async {
    try {
      await _channel.invokeMethod('setEqPreset', preset);
    } catch (_) {}
  }

  static Future<List<double>> getEqBands() async {
    try {
      final result = await _channel.invokeMethod<List>('getEqBands');
      if (result != null) {
        return result.cast<double>();
      }
    } catch (_) {}
    return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  }

  static Future<void> setEqBands(List<double> bands) async {
    try {
      await _channel.invokeMethod('setEqBands', bands);
    } catch (_) {}
  }

  // Bass Boost
  static Future<bool> getBassBoost() async {
    try {
      return await _channel.invokeMethod<bool>('getBassBoost') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBassBoost(bool enabled) async {
    try {
      await _channel.invokeMethod('setBassBoost', enabled);
    } catch (_) {}
  }

  // Spatial Audio
  static Future<bool> getSpatialAudio() async {
    try {
      return await _channel.invokeMethod<bool>('getSpatialAudio') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setSpatialAudio(bool enabled) async {
    try {
      await _channel.invokeMethod('setSpatialAudio', enabled);
    } catch (_) {}
  }

  // Dolby Atmos
  static Future<Map<String, dynamic>> getDolbyAtmosInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getDolbyAtmosInfo');
      return result ?? {};
    } catch (_) {
      return {};
    }
  }

  // Lossless Info
  static Future<Map<String, dynamic>> getLosslessInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getLosslessInfo');
      return result ?? {};
    } catch (_) {
      return {};
    }
  }

  // App Info
  static Future<Map<String, dynamic>> getAppInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getAppInfo');
      return result ?? {};
    } catch (_) {
      return {};
    }
  }

  // Cache
  static Future<void> clearCache() async {
    try {
      await _channel.invokeMethod('clearCache');
    } catch (_) {}
  }

  // Reset
  static Future<void> resetPreferences() async {
    try {
      await _channel.invokeMethod('resetPreferences');
    } catch (_) {}
  }
}