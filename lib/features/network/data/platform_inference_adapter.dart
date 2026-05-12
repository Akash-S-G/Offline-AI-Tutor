import 'package:offline_tutor_app/features/chat/data/tutor_inference_gateway.dart';
import 'package:offline_tutor_app/features/network/domain/local_inference_source.dart';

/// Adapter to use existing TutorInferenceGateway as LocalInferenceSource.
class PlatformInferenceAdapter implements LocalInferenceSource {
  PlatformInferenceAdapter(this._gateway);

  final TutorInferenceGateway _gateway;

  @override
  bool get isReady => true; // Platform gateway is always ready

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

  @override
  Future<void> ensureModelLoaded() async {
    // Model is already loaded in native code
  }

  @override
  void dispose() {
    // Gateway lifecycle is managed elsewhere
  }
}
