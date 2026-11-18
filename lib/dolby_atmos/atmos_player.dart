import 'package:flutter/services.dart';

class AtmosPlayerService {
  static const MethodChannel _channel = MethodChannel('aurabeat/dolby_atmos');

  Future<bool> load(
    String url, {
    String? title,
    String? artist,
    String? album,
    double? durationSeconds,
    String? codec,
    bool? hasJoc,
    String? jocState,
    String? channelLayout,
    int? bandwidth,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'load',
        {
          'url': url,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (album != null) 'album': album,
          if (durationSeconds != null) 'duration': durationSeconds,
          if (codec != null) 'codec': codec,
          if (hasJoc != null) 'hasJoc': hasJoc,
          if (jocState != null) 'jocState': jocState,
          if (channelLayout != null) 'channelLayout': channelLayout,
          if (bandwidth != null) 'bandwidth': bandwidth,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to load Dolby Atmos stream: ${e.message}');
    } catch (e) {
      return false;
    }
  }

  Future<void> play() async {
    try {
      await _channel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } catch (_) {}
  }

  Future<void> seek(double seconds) async {
    try {
      await _channel.invokeMethod(
        'seek',
        {'seconds': seconds},
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> status() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'status',
      );
      return result ?? {};
    } catch (_) {
      return {
        'loaded': false,
        'playing': false,
        'status': 'unavailable',
      };
    }
  }

  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (_) {}
  }
}
