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
  Stream<String> streamResponse({required String prompt}) async* {
    print('[DIAGNOSTICS] ENTERING PlatformTutorInferenceGateway.streamResponse()');
    print('[DIAGNOSTICS] GENERATION_START (PLATFORM)');
    Stream<String> sourceStream;

    if (Platform.isLinux) {
      sourceStream = _linuxGateway.streamResponse(prompt: prompt);
    } else {
      sourceStream = _streamChannel
          .receiveBroadcastStream(<String, dynamic>{'question': prompt})
          .where((event) => event is String)
          .cast<String>()
          .where((chunk) => chunk.isNotEmpty);
    }

    var isFirstToken = true;
    try {
      await for (final chunk in sourceStream) {
        if (isFirstToken) {
          print('[DIAGNOSTICS] FIRST_TOKEN (PLATFORM)');
          isFirstToken = false;
        }
        yield chunk;
      }
    } finally {
      print('[DIAGNOSTICS] GENERATION_END (PLATFORM)');
    }
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
