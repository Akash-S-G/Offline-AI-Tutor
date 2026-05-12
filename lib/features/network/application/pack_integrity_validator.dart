class PackIntegrityValidator {
  const PackIntegrityValidator();

  bool validateManifest({required String packId, required int version, required String checksum}) {
    return packId.isNotEmpty && version > 0 && checksum.isNotEmpty;
  }
}
