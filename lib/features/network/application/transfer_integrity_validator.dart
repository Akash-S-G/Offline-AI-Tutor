class TransferIntegrityValidator {
  const TransferIntegrityValidator();

  bool validate({required String checksum, required String expectedChecksum}) {
    return checksum.isNotEmpty && checksum == expectedChecksum;
  }
}
