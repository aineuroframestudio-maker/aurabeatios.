import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/addon_source_model.dart';
import '../models/audio_quality_models.dart';
import '../services/addon_quality_manager.dart';
import '../services/addon_cache_manager.dart';
import '../services/lossless_output_manager.dart';
import '../services/addon_logger.dart';
import 'addon_protocol_adapter.dart';

/// Concrete protocol adapter for BitChord-compatible add-on servers.
/// Implements standard BitChord REST wire contract strictly:
/// - GET /manifest.json
/// - GET /search?q={query}&quality={quality}&{other_settings_defaults}
/// - GET /stream/{id}?quality={quality}&{other_settings_defaults}
class BitChordProtocolAdapter extends AddonProtocolAdapter {
  final http.Client _client;
  final AddonCacheManager _cache;
  final LosslessOutputManager _outputManager;

  BitChordProtocolAdapter(
    super.config, {
    http.Client? client,
    AddonCacheManager? cache,
    LosslessOutputManager? outputManager,
  })  : _client = client ?? http.Client(),
        _cache = cache ?? AddonCacheManager.instance,
        _outputManager = outputManager ?? LosslessOutputManager.instance;

  @override
  Future<AddonConnectionStatus> checkHealth() async {
    try {
      final uri = Uri.parse(config.manifestUrl);
      final resp = await _client.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'BitChord/1.9.1 (AuraBeat-Compatible)'},
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        config.lastSuccess = DateTime.now();
        config.lastError = null;

        if (config.bitchordAuth) {
          return AddonConnectionStatus.authRequired;
        }
        return AddonConnectionStatus.connected;
      } else if (resp.statusCode == 503) {
        config.lastError = 'HTTP 503 Degraded';
        return AddonConnectionStatus.degraded;
      } else if (resp.statusCode == 404) {
        config.lastError = 'HTTP 404 Offline';
        return AddonConnectionStatus.offline;
      } else {
        return AddonConnectionStatus.connected;
      }
    } catch (e) {
      config.lastError = e.toString();
      return AddonConnectionStatus.offline;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required String quality,
    String? atmos,
    int limit = 20,
  }) async {
    // Lossless output gate check: if source requires valid lossless and output does not qualify, abort
    if (!_outputManager.shouldAllowGatedSource(config)) {
      AddonLogger.addonError(
        operation: 'search_output_gate',
        addonId: config.id,
        errorCategory: 'lossless_output_gated',
        details: 'checkValidLossless is true and current output does not qualify as lossless',
      );
      return [];
    }

    // Effective quality according to BitChord Rule 1 & Rule 3
    final effectiveQuality = config.selectedQualityOption ?? quality;

    // Check in-memory cache
    final cached = _cache.getSearchResults(
      sourceId: config.id,
      query: query,
      quality: effectiveQuality,
      atmos: atmos,
    );
    if (cached != null) {
      return cached;
    }

    final queryParams = <String, String>{
      'q': query,
      'quality': effectiveQuality,
    };

    // BitChord Spec: Every other setting sends its scalar default value
    config.rawSettings.forEach((key, settingMap) {
      if (key != 'quality' && settingMap is Map && settingMap['default'] != null) {
        queryParams[key] = settingMap['default'].toString();
      }
    });

    if (atmos != null && atmos.isNotEmpty) {
      queryParams['atmos'] = atmos;
    }

    AddonLogger.searchStarted(query, config.id, effectiveQuality);

    try {
      final uri = Uri.parse('${config.url}/search').replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'BitChord/1.9.1 (AuraBeat-Compatible)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        config.lastSuccess = DateTime.now();
        config.lastError = null;

        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['tracks'] is List) {
          final rawTracks = (decoded['tracks'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
          final mappedTracks = rawTracks
              .where((t) => (t['id']?.toString() ?? '').isNotEmpty && (t['title']?.toString() ?? '').isNotEmpty)
              .take(limit)
              .map((t) {
            final isTrackAtmos = t['atmos'] == true ||
                t['audioMode'] == 'DOLBY_ATMOS' ||
                (t['audioModes'] is List && (t['audioModes'] as List).contains('DOLBY_ATMOS'));
            return {
              ...t,
              'sourceId': config.id,
              'sourceName': config.name,
              'negotiatedQuality': effectiveQuality,
              'isDolbyAtmos': isTrackAtmos,
              'isLosslessGated': config.checkValidLossless,
            };
          }).toList();

          AddonLogger.searchResponseReceived(config.id, response.statusCode, mappedTracks.length);

          _cache.putSearchResults(
            sourceId: config.id,
            query: query,
            quality: effectiveQuality,
            atmos: atmos,
            results: mappedTracks,
          );
          return mappedTracks;
        }
      } else if (response.statusCode == 401) {
        // Genuine bitchordAuth requirement
        config.status = AddonConnectionStatus.authRequired;
        config.statusMessage = 'bitchordAuth REQUIRED (Hardware KeyStore Attestation)';
        config.lastError = 'HTTP 401 bitchordAuth Required';
        AddonLogger.addonError(
          operation: 'search',
          addonId: config.id,
          httpStatus: 401,
          errorCategory: 'bitchord_auth',
          endpointPath: '/search',
          details: 'Hardware attestation required by addon server',
        );
        return [];
      } else if (response.statusCode == 404) {
        // Genuine 404: return empty so fallback chain advances
        config.lastError = 'HTTP 404 Not Found';
        AddonLogger.searchResponseReceived(config.id, 404, 0);
        return [];
      } else {
        config.lastError = 'HTTP ${response.statusCode}';
        AddonLogger.addonError(
          operation: 'search',
          addonId: config.id,
          httpStatus: response.statusCode,
          errorCategory: 'http_error',
          endpointPath: '/search',
          details: response.body,
        );
        return [];
      }
    } catch (e) {
      config.lastError = e.toString();
      AddonLogger.searchError(config.id, query, e.toString());
      return [];
    }

    return [];
  }

  @override
  Future<ResolvedStream?> resolveStream({
    required String trackId,
    required String quality,
    String? atmos,
    String? title,
    String? artist,
  }) async {
    // Lossless output gate check
    if (!_outputManager.shouldAllowGatedSource(config)) {
      AddonLogger.addonError(
        operation: 'stream_output_gate',
        addonId: config.id,
        errorCategory: 'lossless_output_gated',
        details: 'checkValidLossless is true and current output does not qualify as lossless',
      );
      return null;
    }

    final effectiveQuality = config.selectedQualityOption ?? quality;

    // Check in-memory stream cache
    final cachedStream = _cache.getResolvedStream(
      sourceId: config.id,
      trackId: trackId,
      quality: effectiveQuality,
      atmos: atmos,
    );
    if (cachedStream != null) {
      return cachedStream;
    }

    final queryParams = <String, String>{
      'quality': effectiveQuality,
    };

    if (title != null && title.isNotEmpty) {
      queryParams['title'] = title;
    }
    if (artist != null && artist.isNotEmpty) {
      queryParams['artist'] = artist;
    }

    // BitChord Spec: Send other settings default scalar values
    config.rawSettings.forEach((key, settingMap) {
      if (key != 'quality' && settingMap is Map && settingMap['default'] != null) {
        queryParams[key] = settingMap['default'].toString();
      }
    });

    if (atmos != null && atmos.isNotEmpty) {
      queryParams['atmos'] = atmos;
    }

    AddonLogger.streamResolutionStarted(trackId, config.id, effectiveQuality);

    try {
      final encodedId = Uri.encodeComponent(trackId);
      final uri = Uri.parse('${config.url}/stream/$encodedId').replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'BitChord/1.9.1 (AuraBeat-Compatible)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        config.lastSuccess = DateTime.now();
        config.lastError = null;

        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('url') && decoded['url'] != null) {
          final streamUrl = decoded['url'].toString();
          if (streamUrl.isNotEmpty && (streamUrl.startsWith('https://') || streamUrl.startsWith('http://'))) {
            final metadata = AddonQualityManager.instance.verifyMetadata(
              streamJson: decoded,
              sourceId: config.id,
              sourceName: config.name,
            );

            final resolved = ResolvedStream(
              trackId: trackId,
              url: streamUrl,
              negotiatedQuality: effectiveQuality,
              metadata: metadata,
              sourceId: config.id,
              sourceName: config.name,
              isDASH: metadata.container.contains('dash') || metadata.streamType.contains('DASH'),
              isHLS: metadata.container.contains('hls') || metadata.streamType.contains('HLS'),
            );

            AddonLogger.streamResolved(
              trackId: trackId,
              sourceId: config.id,
              codec: metadata.codec,
              sampleRate: metadata.sampleRateHz,
              bitDepth: metadata.bitDepth,
              bitrate: metadata.bitrateKbps,
              quality: metadata.summaryQualityLabel,
            );

            _cache.putResolvedStream(
              sourceId: config.id,
              trackId: trackId,
              quality: effectiveQuality,
              atmos: atmos,
              stream: resolved,
            );

            return resolved;
          }
        }
      } else if (response.statusCode == 401) {
        config.status = AddonConnectionStatus.authRequired;
        config.statusMessage = 'bitchordAuth REQUIRED';
        config.lastError = 'HTTP 401 Unauthorized';
        AddonLogger.addonError(
          operation: 'stream',
          addonId: config.id,
          httpStatus: 401,
          errorCategory: 'bitchord_auth',
          endpointPath: '/stream/$trackId',
          details: 'Hardware attestation token required',
        );
        return null;
      } else if (response.statusCode == 404) {
        // Genuine 404 allows fallback to the next provider
        config.lastError = 'HTTP 404 Not Found';
        AddonLogger.streamError(trackId, config.id, 'HTTP 404 Track not found in this addon');
        return null;
      } else {
        config.lastError = 'HTTP ${response.statusCode}';
        AddonLogger.streamError(trackId, config.id, 'HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      config.lastError = e.toString();
      AddonLogger.streamError(trackId, config.id, e.toString());
      return null;
    }

    return null;
  }
}
