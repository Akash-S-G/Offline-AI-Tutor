import 'dart:io';

import 'package:flutter/services.dart';

import 'linux_tutor_inference_gateway.dart';
import 'tutor_inference_gateway.dart';

class PlatformTutorInferenceGateway implements TutorInferenceGateway {
  static const MethodChannel _channel = MethodChannel('offline_tutor/llm');
  static const EventChannel _streamChannel = EventChannel('offline_tutor/llm_stream');
  static const EventChannel _metricsChannel = EventChannel('offline_tutor/llm_metrics');
  final LinuxTutorInferenceGateway _linuxGateway = LinuxTutorInferenceGateway();

  @override
  Stream<String> streamResponse({required String prompt}) {
    if (Platform.isLinux) {
      return _linuxGateway.streamResponse(prompt: prompt);
    }

    return _streamChannel
        .receiveBroadcastStream(<String, dynamic>{'question': prompt})
        .where((event) => event is String)
        .cast<String>()
      .where((chunk) => chunk.isNotEmpty);
  }

  @override
  Stream<Map<String, dynamic>> metricsStream() {
    if (Platform.isLinux) {
      return _linuxGateway.metricsStream();
    }

    return _metricsChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => Map<dynamic, dynamic>.from(event as Map))
        .map(
          (map) => <String, dynamic>{
            'totalMs': map['totalMs'],
            'tokens': map['tokens'],
            'tokensPerSec': map['tokensPerSec'],
          },
        );
  }

  @override
  Future<void> stopGeneration() async {
    if (Platform.isLinux) {
      await _linuxGateway.stopGeneration();
      return;
    }

    await _channel.invokeMethod<Map<dynamic, dynamic>>('stopGeneration');
  }
}
