class BackendAvailabilityCache {
  static final BackendAvailabilityCache _instance = BackendAvailabilityCache._internal();

  factory BackendAvailabilityCache() {
    return _instance;
  }

  BackendAvailabilityCache._internal();

  bool? _isAvailable;
  DateTime? _lastChecked;
  final Duration _cacheDuration = const Duration(minutes: 5);

  /// Returns the cached availability status, or null if expired/never checked.
  bool? get cachedStatus {
    if (_isAvailable == null || _lastChecked == null) {
      return null;
    }
    
    final age = DateTime.now().difference(_lastChecked!);
    if (age > _cacheDuration) {
      return null;
    }
    
    return _isAvailable;
  }

  /// Updates the cached status and last checked time.
  void updateStatus(bool available) {
    _isAvailable = available;
    _lastChecked = DateTime.now();
  }

  /// Clears the cache.
  void clear() {
    _isAvailable = null;
    _lastChecked = null;
  }
}
