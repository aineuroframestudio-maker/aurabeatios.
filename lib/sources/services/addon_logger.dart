import 'package:flutter/foundation.dart';

/// Structured diagnostic logging utility for AuraBeat BitChord Add-on ecosystem.
/// Formats structured logs for [ADDON], [SEARCH], [QUALITY], [STREAM], and [PLAYER]
/// without exposing private credentials, hardware keys, tokens, or sensitive signed URLs.
class AddonLogger {
  static final List<String> _recentLogs = [];
  static const int _maxLogs = 200;

  static List<String> get recentLogs => List.unmodifiable(_recentLogs);

  static void _log(String tag, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '[$timestamp] [$tag] $message';
    _recentLogs.add(formatted);
    if (_recentLogs.length > _maxLogs) {
      _recentLogs.removeAt(0);
    }
    debugPrint(formatted);
  }

  // --- ADDON LIFE-CYCLE ---
  static void addonInstallStarted(String url) {
    _log('ADDON', 'Installation started for URL: $url');
  }

  static void addonManifestRequested(String manifestUrl) {
    _log('ADDON', 'Manifest request started: $manifestUrl');
  }

  static void addonManifestReceived(String url, int statusCode, int contentLength) {
    _log('ADDON', 'Manifest response received from $url: HTTP $statusCode ($contentLength bytes)');
  }

  static void addonManifestParsed(String id, String name, String version, int qualityOptionsCount) {
    _log('ADDON', 'Manifest parsing successful: id="$id", name="$name", version=v$version, qualityOptions=$qualityOptionsCount');
  }

  static void addonSaved(String id, String name) {
    _log('ADDON', 'Addon saved successfully into persistent storage: id="$id", name="$name"');
  }

  static void addonLoadedIntoUI(String id, String name) {
    _log('ADDON', 'Addon loaded into UI: id="$id", name="$name"');
  }

  static void addonError({
    required String operation,
    String? addonId,
    int? httpStatus,
    required String errorCategory,
    String? endpointPath,
    required String details,
  }) {
    final statusStr = httpStatus != null ? ' HTTP $httpStatus' : '';
    final idStr = addonId != null ? ' (addon: $addonId)' : '';
    final pathStr = endpointPath != null ? ' at $endpointPath' : '';
    _log(
      'ADDON ERROR',
      'Operation: $operation$idStr$statusStr$pathStr [$errorCategory] -> $details',
    );
  }

  // --- SEARCH ---
  static void searchStarted(String query, String sourceId, String quality) {
    _log('SEARCH', 'Search started: query="$query", source="$sourceId", quality="$quality"');
  }

  static void searchResponseReceived(String sourceId, int statusCode, int trackCount) {
    _log('SEARCH', 'Search response received: source="$sourceId", status=HTTP $statusCode, tracks=$trackCount');
  }

  static void searchError(String sourceId, String query, String details) {
    _log('SEARCH ERROR', 'Search failed for source="$sourceId", query="$query": $details');
  }

  // --- QUALITY ---
  static void qualityOptionsLoaded(String sourceId, List<String> options) {
    _log('QUALITY', 'Manifest quality options loaded for source="$sourceId": [${options.join(", ")}]');
  }

  static void qualitySelected(String sourceId, String qualityValue, String label) {
    _log('QUALITY', 'Selected quality updated: source="$sourceId" -> value="$qualityValue" ("$label")');
  }

  // --- STREAM ---
  static void streamResolutionStarted(String trackId, String sourceId, String quality) {
    _log('STREAM', 'Stream resolution started: trackId="$trackId", source="$sourceId", quality="$quality"');
  }

  static void streamResolved({
    required String trackId,
    required String sourceId,
    required String codec,
    int? sampleRate,
    int? bitDepth,
    int? bitrate,
    required String quality,
  }) {
    final srStr = sampleRate != null ? ' ${sampleRate}Hz' : '';
    final bdStr = bitDepth != null ? ' $bitDepth-bit' : '';
    final brStr = bitrate != null ? ' ${bitrate}kbps' : '';
    _log('STREAM', 'Stream resolved: trackId="$trackId", source="$sourceId", codec=$codec$bdStr$srStr$brStr, tier="$quality"');
  }

  static void streamError(String trackId, String sourceId, String details) {
    _log('STREAM ERROR', 'Stream resolution failed for trackId="$trackId", source="$sourceId": $details');
  }

  // --- PLAYER ---
  static void playbackInitialized(String trackId, String title, String sourceName, String codec) {
    _log('PLAYER', 'Playback initialized: trackId="$trackId" ("$title") from source="$sourceName" with codec=$codec');
  }
}
