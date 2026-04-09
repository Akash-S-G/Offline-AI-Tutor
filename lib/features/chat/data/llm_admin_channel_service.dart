import 'package:flutter/services.dart';

class ModelMetadata {
  const ModelMetadata({
    required this.path,
    required this.sizeBytes,
    required this.lastSelectedAtMillis,
  });

  final String path;
  final int sizeBytes;
  final int lastSelectedAtMillis;
}

class GenerationConfig {
  const GenerationConfig({
    required this.maxTokens,
    required this.timeoutMs,
    required this.systemPrompt,
  });

  final int maxTokens;
  final int timeoutMs;
  final String systemPrompt;
}

class EngineStatus {
  const EngineStatus({
    required this.loaded,
    required this.modelPath,
    required this.lastEngineError,
    required this.totalInferenceCount,
    required this.lastInferenceDurationMs,
    required this.avgInferenceDurationMs,
  });

  final bool loaded;
  final String modelPath;
  final String lastEngineError;
  final int totalInferenceCount;
  final int lastInferenceDurationMs;
  final int avgInferenceDurationMs;
}

class LlmAdminChannelService {
  static const MethodChannel _channel = MethodChannel('offline_tutor/llm');
  static const EventChannel _modelCopyProgressChannel = EventChannel('offline_tutor/model_copy_progress');

  Stream<int> get modelCopyProgress => _modelCopyProgressChannel.receiveBroadcastStream().cast<int>();

  Future<String?> getModelPath() {
    return _channel.invokeMethod<String>('getModelPath');
  }

  Future<bool> setModelPath(String modelPath) async {
    final response = await _channel.invokeMethod<bool>(
      'setModelPath',
      <String, dynamic>{'modelPath': modelPath},
    );
    return response ?? false;
  }

  Future<ModelMetadata> getModelMetadata() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'getModelMetadata',
    );

    return ModelMetadata(
      path: response?['path'] as String? ?? '',
      sizeBytes: response?['sizeBytes'] as int? ?? 0,
      lastSelectedAtMillis: response?['lastSelectedAtMillis'] as int? ?? 0,
    );
  }

  Future<GenerationConfig> getGenerationConfig() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'getGenerationConfig',
    );

    return GenerationConfig(
      maxTokens: response?['maxTokens'] as int? ?? 256,
      timeoutMs: response?['timeoutMs'] as int? ?? 120000,
      systemPrompt: response?['systemPrompt'] as String? ?? '',
    );
  }

  Future<GenerationConfig> updateGenerationConfig({
    int? maxTokens,
    int? timeoutMs,
    String? systemPrompt,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'updateGenerationConfig',
      <String, dynamic>{
        'maxTokens': maxTokens,
        'timeoutMs': timeoutMs,
        'systemPrompt': systemPrompt,
      },
    );

    return GenerationConfig(
      maxTokens: response?['maxTokens'] as int? ?? 256,
      timeoutMs: response?['timeoutMs'] as int? ?? 120000,
      systemPrompt: response?['systemPrompt'] as String? ?? '',
    );
  }

  Future<EngineStatus> getEngineStatus() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'getEngineStatus',
    );

    return EngineStatus(
      loaded: response?['loaded'] as bool? ?? false,
      modelPath: response?['modelPath'] as String? ?? '',
      lastEngineError: response?['lastEngineError'] as String? ?? '',
      totalInferenceCount: response?['totalInferenceCount'] as int? ?? 0,
      lastInferenceDurationMs: response?['lastInferenceDurationMs'] as int? ?? 0,
      avgInferenceDurationMs: response?['avgInferenceDurationMs'] as int? ?? 0,
    );
  }

  Future<bool> preloadModel() async {
    final response = await _channel.invokeMethod<bool>('preloadModel');
    return response ?? false;
  }

  Future<Map<String, dynamic>> runPerformanceProbe({
    int iterations = 1,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'runPerformanceProbe',
      <String, dynamic>{'iterations': iterations},
    );
    return response ?? const <String, dynamic>{};
  }

  Future<bool> resetEngine() async {
    final response = await _channel.invokeMethod<bool>('resetEngine');
    return response ?? false;
  }

  Future<Map<String, dynamic>> runEngineSelfTest() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'runEngineSelfTest',
    );
    return response ?? const <String, dynamic>{};
  }
}
