class LocalPackPersistenceCoordinator {
  final Map<String, Map<String, dynamic>> _packs = <String, Map<String, dynamic>>{};

  void persist(String packId, Map<String, dynamic> payload) {
    _packs[packId] = Map<String, dynamic>.from(payload);
  }

  Map<String, dynamic>? load(String packId) => _packs[packId];
}
