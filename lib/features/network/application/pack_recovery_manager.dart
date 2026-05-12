import 'pack_version_manager.dart';

class PackRecoveryManager {
  const PackRecoveryManager();

  bool canResume({required PackManifest manifest, required int downloadedBytes, required int totalBytes}) {
    return downloadedBytes > 0 && downloadedBytes < totalBytes;
  }
}
