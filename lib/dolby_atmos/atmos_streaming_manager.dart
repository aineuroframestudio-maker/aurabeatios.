import 'package:http/http.dart' as http;

import 'hls_inspector.dart';
import 'atmos_player.dart';

class AtmosStreamingManager {
  final AtmosPlayerService player;
  final http.Client _httpClient;

  AtmosStreamInfo? _lastStreamInfo;
  String? _activeStreamUrl;
  bool _isAtmosSource = false;
  bool _is51Fallback = false;
  bool _isStereoFallback = false;

  AtmosStreamingManager({
    AtmosPlayerService? playerService,
    http.Client? httpClient,
  })  : player = playerService ?? AtmosPlayerService(),
        _httpClient = httpClient ?? http.Client();

  AtmosStreamInfo? get lastStreamInfo => _lastStreamInfo;
  String? get activeStreamUrl => _activeStreamUrl;
  bool get isAtmosSource => _isAtmosSource;
  bool get is51Fallback => _is51Fallback;
  bool get isStereoFallback => _isStereoFallback;

  Future<AtmosStreamInfo> inspectStream(
    String manifestUrl,
  ) async {
    final response = await _httpClient.get(
      Uri.parse(manifestUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to retrieve HLS manifest (HTTP ${response.statusCode})',
      );
    }

    final info = HlsAtmosInspector.inspect(
      response.body,
    );

    _lastStreamInfo = info;
    return info;
  }

  Future<void> playAuthorizedStream(
    String manifestUrl, {
    String? title,
    String? artist,
    String? album,
    double? durationSeconds,
    bool allowFallback = true,
  }) async {
    final info = await inspectStream(
      manifestUrl,
    );

    String playUrl = manifestUrl;
    _isAtmosSource = false;
    _is51Fallback = false;
    _isStereoFallback = false;

    final atmosVariant = info.variants.cast<HlsAudioVariant?>().firstWhere(
      (v) => v != null && v.isAtmos,
      orElse: () => null,
    );
    final d51Variant = info.variants.cast<HlsAudioVariant?>().firstWhere(
      (v) => v != null && v.isDolby51,
      orElse: () => null,
    );
    final stereoVariant = info.variants.cast<HlsAudioVariant?>().firstWhere(
      (v) => v != null && v.isStereo,
      orElse: () => null,
    );

    HlsAudioVariant? selectedVariant;

    if (info.isAtmosCandidate && atmosVariant != null) {
      // 1. Dolby Atmos E-AC-3 JOC
      _isAtmosSource = true;
      selectedVariant = atmosVariant;
    } else if (info.isDolbyDigitalPlus && d51Variant != null) {
      // 2. Compatible Dolby 5.1
      _is51Fallback = true;
      selectedVariant = d51Variant;
    } else if (allowFallback && stereoVariant != null) {
      // 3. Stereo AAC fallback
      _isStereoFallback = true;
      selectedVariant = stereoVariant;
    } else if (!info.isDolbyDigitalPlus && !info.isAtmosCandidate) {
      // 4. Clear playback error
      throw Exception(
        'E-AC-3 stream not found',
      );
    }

    if (selectedVariant != null) {
      if (!selectedVariant.uri.startsWith('http')) {
        playUrl = _resolveRelativeUri(manifestUrl, selectedVariant.uri);
      } else {
        playUrl = selectedVariant.uri;
      }
    }

    _activeStreamUrl = playUrl;

    final selectedCodec = selectedVariant?.codec ?? (info.isAtmosCandidate ? 'ec-3' : info.codec);
    final selectedHasJoc = selectedVariant?.isAtmos ?? info.hasJocMetadata;
    final selectedJocState = selectedHasJoc ? 'inferred from manifest signalling' : 'unverified';
    final selectedChannelLayout = selectedVariant?.channels ?? info.channels;
    final selectedBandwidth = selectedVariant?.bandwidth ?? info.bandwidth;

    await player.load(
      playUrl,
      title: title,
      artist: artist,
      album: album,
      durationSeconds: durationSeconds,
      codec: selectedCodec,
      hasJoc: selectedHasJoc,
      jocState: selectedJocState,
      channelLayout: selectedChannelLayout,
      bandwidth: selectedBandwidth,
    );

    await player.play();
  }

  String _resolveRelativeUri(String baseUri, String relative) {
    try {
      final base = Uri.parse(baseUri);
      return base.resolve(relative).toString();
    } catch (_) {
      return relative;
    }
  }

  Future<void> stop() async {
    await player.pause();
  }

  Future<void> dispose() async {
    await player.dispose();
    _httpClient.close();
  }
}
