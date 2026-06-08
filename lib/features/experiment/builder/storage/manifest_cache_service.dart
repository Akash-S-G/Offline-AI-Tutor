import 'dart:convert';
import 'package:crypto/crypto.dart';

class ManifestCacheService {
  // Singleton instance
  static final ManifestCacheService _instance = ManifestCacheService._internal();
  factory ManifestCacheService() => _instance;
  ManifestCacheService._internal();

  final Map<String, Map<String, dynamic>> _cache = {};

  /// Caches a manifest and returns its SHA-256 hash key
  String cacheManifest(Map<String, dynamic> manifest) {
    // Generate deterministic hash string
    final jsonStr = jsonEncode(manifest);
    final hash = sha256.convert(utf8.encode(jsonStr)).toString();
    _cache[hash] = manifest;
    return hash;
  }

  /// Retrieves a manifest by its hash, returning null if missing or evicted
  Map<String, dynamic>? getManifest(String hash) {
    return _cache[hash];
  }

  /// Clears the entire cache. Use during high-memory warnings or user logout.
  void clear() {
    _cache.clear();
  }

  /// Removes a specific item from the cache
  void evict(String hash) {
    _cache.remove(hash);
  }

  int get size => _cache.length;
}
