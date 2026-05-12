class PackManifest {
  const PackManifest({required this.packId, required this.version, required this.checksum});
  final String packId;
  final int version;
  final String checksum;
}

class PackVersionManager {
  final Map<String, PackManifest> _manifests = {};

  void record(PackManifest manifest) {
    _manifests[manifest.packId] = manifest;
  }

  bool needsUpdate(PackManifest incoming) {
    final current = _manifests[incoming.packId];
    if (current == null) return true;
    if (incoming.version > current.version) return true;
    return incoming.checksum != current.checksum;
  }
}
