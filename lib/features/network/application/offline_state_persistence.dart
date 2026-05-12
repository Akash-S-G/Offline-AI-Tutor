class OfflineStatePersistence {
  final Map<String, dynamic> _state = <String, dynamic>{};

  void save(String key, dynamic value) {
    _state[key] = value;
  }

  T? load<T>(String key) => _state[key] as T?;
}
