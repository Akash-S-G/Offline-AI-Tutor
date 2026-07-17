import 'package:flutter/services.dart';
import 'package:offline_tutor_app/features/chat/data/llm_admin_channel_service.dart';
import 'package:offline_tutor_app/features/chat/data/tutor_inference_gateway.dart';
import 'package:offline_tutor_app/features/network/domain/local_inference_source.dart';

/// Adapter to use existing TutorInferenceGateway as LocalInferenceSource.
///
/// On Android the readiness is backed by the native LlamaEngine status queried
/// via [LlmAdminChannelService]. On Linux the gateway manages readiness itself
/// so we fall back to [true] when the MethodChannel is unavailable.
class PlatformInferenceAdapter implements LocalInferenceSource {
  PlatformInferenceAdapter(this._gateway);

  final TutorInferenceGateway _gateway;
  final LlmAdminChannelService _adminChannel = LlmAdminChannelService();

  /// Cached readiness — updated by [ensureModelLoaded].
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Stream<String> streamQuestion(String question) {
    return _gateway.streamResponse(prompt: question);
  }

  @override
  Future<void> stopGeneration() {
    return _gateway.stopGeneration();
  }

  @override
  Future<Map<String, String>> getModelInfo() async {
    return <String, String>{
      'engine': 'llama.cpp',
      'platform': 'native',
    };
  }

  /// Query the native engine status and cache the result in [isReady].
  ///
  /// On Linux the MethodChannel does not exist and a [MissingPluginException]
  /// is thrown. In that case we optimistically mark the adapter as ready so the
  /// Linux gateway can manage its own validation when the process starts.
  @override
  Future<void> ensureModelLoaded() async {
    try {
      final status = await _adminChannel.getEngineStatus();
      _ready = status.loaded;

      if (!_ready) {
        // Fire a background preload and re-check once after a short delay.
        // preloadModel() returns quickly (the native side spins up a thread).
        try {
          await _adminChannel.preloadModel();
        } catch (_) {
          // Ignore — e.g. MissingPluginException on Linux.
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final status2 = await _adminChannel.getEngineStatus();
        _ready = status2.loaded;
      }
    } on MissingPluginException {
      // Linux desktop: MethodChannel not registered → fall back to ready=true
      // so the LinuxTutorInferenceGateway can run its own subprocess.
      _ready = true;
    } catch (_) {
      // Any other unexpected error: conservatively mark not ready.
      _ready = false;
    }
  }

  @override
  void dispose() {
    // Gateway lifecycle is managed elsewhere.
  }
}
