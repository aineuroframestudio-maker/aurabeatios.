import 'dart:collection';
import '../models/audio_quality_models.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory cache manager implementing BitChord documentation TTL policies:
/// - Manifests: 10 minutes TTL
/// - Search results: 10 minutes TTL
/// - Stream resolutions: 5 minutes TTL (to respect short-lived signed URLs)
class AddonCacheManager {
  static final AddonCacheManager instance = AddonCacheManager._internal();

  final Map<String, _CacheEntry<Map<String, dynamic>>> _manifestCache = HashMap();
  final Map<String, _CacheEntry<List<Map<String, dynamic>>>> _searchCache = HashMap();
  final Map<String, _CacheEntry<ResolvedStream>> _streamCache = HashMap();

  static const Duration manifestTtl = Duration(minutes: 10);
  static const Duration searchTtl = Duration(minutes: 10);
  static const Duration streamTtl = Duration(minutes: 5);

  AddonCacheManager._internal();

  // --- Manifest Caching ---
  Map<String, dynamic>? getManifest(String url) {
    final entry = _manifestCache[url];
    if (entry == null) return null;
    if (entry.isExpired) {
      _manifestCache.remove(url);
      return null;
    }
    return entry.data;
  }

  void putManifest(String url, Map<String, dynamic> manifest) {
    _manifestCache[url] = _CacheEntry(
      data: Map.unmodifiable(manifest),
      expiresAt: DateTime.now().add(manifestTtl),
    );
  }

  // --- Search Results Caching ---
  String _buildSearchKey(String sourceId, String query, String quality, String? atmos) {
    return '$sourceId::$query::$quality::${atmos ?? ""}';
  }

  List<Map<String, dynamic>>? getSearchResults({
    required String sourceId,
    required String query,
    required String quality,
    String? atmos,
  }) {
    final key = _buildSearchKey(sourceId, query, quality, atmos);
    final entry = _searchCache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _searchCache.remove(key);
      return null;
    }
    return entry.data;
  }

  void putSearchResults({
    required String sourceId,
    required String query,
    required String quality,
    String? atmos,
    required List<Map<String, dynamic>> results,
  }) {
    final key = _buildSearchKey(sourceId, query, quality, atmos);
    _searchCache[key] = _CacheEntry(
      data: List.unmodifiable(results),
      expiresAt: DateTime.now().add(searchTtl),
    );
  }

  // --- Stream Resolution Caching ---
  String _buildStreamKey(String sourceId, String trackId, String quality, String? atmos) {
    return '$sourceId::$trackId::$quality::${atmos ?? ""}';
  }

  ResolvedStream? getResolvedStream({
    required String sourceId,
    required String trackId,
    required String quality,
    String? atmos,
  }) {
    final key = _buildStreamKey(sourceId, trackId, quality, atmos);
    final entry = _streamCache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _streamCache.remove(key);
      return null;
    }
    return entry.data;
  }

  void putResolvedStream({
    required String sourceId,
    required String trackId,
    required String quality,
    String? atmos,
    required ResolvedStream stream,
  }) {
    final key = _buildStreamKey(sourceId, trackId, quality, atmos);
    _streamCache[key] = _CacheEntry(
      data: stream,
      expiresAt: DateTime.now().add(streamTtl),
    );
  }

  /// Invalidate cache for a specific source
  void invalidateSource(String sourceId) {
    _searchCache.removeWhere((k, _) => k.startsWith('$sourceId::'));
    _streamCache.removeWhere((k, _) => k.startsWith('$sourceId::'));
  }

  /// Clear entire cache
  void clearAll() {
    _manifestCache.clear();
    _searchCache.clear();
    _streamCache.clear();
  }
}
