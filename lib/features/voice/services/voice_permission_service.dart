import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around [permission_handler] for microphone access.
class VoicePermissionService {
  /// Request microphone permission from the OS.
  /// Returns `true` if granted (including "limited" on iOS).
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  /// Check current permission status without prompting.
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted || status.isLimited;
  }
}
