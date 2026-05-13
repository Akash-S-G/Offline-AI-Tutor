import '../../../config/app_environment.dart';
import 'pack_version_manager.dart';

class PackRecoveryManager {
  const PackRecoveryManager();

  bool canResume({required PackManifest manifest, required int downloadedBytes, required int totalBytes}) {
    final canResumeValue = downloadedBytes > 0 && downloadedBytes < totalBytes;
    
    if (canResumeValue) {
      AppEnvironment.log(
        'RECOVERY',
        'Can resume download for pack ${manifest.packId}: $downloadedBytes / $totalBytes bytes',
      );
    } else {
      AppEnvironment.log(
        'RECOVERY',
        'Cannot resume download for pack ${manifest.packId}: $downloadedBytes / $totalBytes bytes',
      );
    }
    
    return canResumeValue;
  }
}
