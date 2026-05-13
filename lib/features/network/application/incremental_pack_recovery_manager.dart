import '../../../config/app_environment.dart';

class IncrementalPackRecoveryManager {
  const IncrementalPackRecoveryManager();

  bool canResume({required int downloadedBytes, required int totalBytes}) {
    final canResumeValue = downloadedBytes > 0 && downloadedBytes < totalBytes;
    
    if (canResumeValue) {
      AppEnvironment.log(
        'RECOVERY',
        'Can resume incremental download: $downloadedBytes / $totalBytes bytes',
      );
    }
    
    return canResumeValue;
  }
}
