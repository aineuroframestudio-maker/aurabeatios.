class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory and session cache for recommendation calculations with TTL support.
class RecommendationCache {
  final Map<String, _CacheEntry<dynamic>> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 10)}) {
    _cache[key] = _CacheEntry<T>(value, DateTime.now().add(ttl));
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidateAll() {
    _cache.clear();
  }
}
