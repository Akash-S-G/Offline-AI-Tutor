import 'package:flutter/services.dart';

class RuntimeOrientationLock {
  const RuntimeOrientationLock._();

  static Future<void> lockLandscape() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> restore() {
    return SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
