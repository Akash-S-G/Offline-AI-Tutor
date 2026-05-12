class IncrementalPackRecoveryManager {
  const IncrementalPackRecoveryManager();

  bool canResume({required int downloadedBytes, required int totalBytes}) {
    return downloadedBytes > 0 && downloadedBytes < totalBytes;
  }
}
