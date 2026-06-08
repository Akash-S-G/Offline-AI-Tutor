import '../../network/data/backend_availability_cache.dart';
import '../../../config/app_environment.dart';

/// Single source of truth for the runtime-discovered backend URL.
///
/// All services that need the backend URL must read [current] instead of
/// calling [AppEnvironment.backendBaseUrl] or [EndpointBuilder.fromEnvironment()].
///
/// Updated by [BackendUrlManager] whenever discovery promotes a new node.
class RuntimeBackendUrl {
  static final RuntimeBackendUrl _instance = RuntimeBackendUrl._internal();
  factory RuntimeBackendUrl() => _instance;
  RuntimeBackendUrl._internal();

  String _url = '';

  /// The currently active backend URL.
  /// Falls back to the .env value on first boot before discovery completes.
  String get current =>
      _url.isNotEmpty ? _url : AppEnvironment.backendBaseUrl;

  /// Called by [BackendUrlManager] when a new node is promoted.
  void updateUrl(String newUrl) {
    if (newUrl.isEmpty || newUrl == _url) return;
    final old = _url.isNotEmpty ? _url : AppEnvironment.backendBaseUrl;
    _url = newUrl;
    print('[URL_SWITCH] old=$old new=$newUrl');
    // Invalidate the availability cache so the next health check uses the new URL.
    BackendAvailabilityCache().clear();
    print('[URL] CACHE_INVALIDATED (backend URL switched)');
  }
}
