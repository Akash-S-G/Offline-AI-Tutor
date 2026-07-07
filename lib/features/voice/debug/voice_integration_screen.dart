import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../language/providers/language_provider.dart';

import '../../../features/tutor/screens/voice_tutor_screen.dart';
import '../models/connection_status.dart';
import '../models/voice_event.dart';
import '../providers/voice_connection_provider.dart';
import '../services/voice_socket_service.dart';

/// A mock implementation of [VoiceSocketService] that fakes the AI backend.
class MockVoiceSocketService extends VoiceSocketService {
  final _mockEventController = StreamController<VoiceEvent>.broadcast();
  final _mockStatusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  Stream<VoiceEvent> get eventStream => _mockEventController.stream;

  @override
  Stream<ConnectionStatus> get statusStream => _mockStatusController.stream;

  @override
  ConnectionStatus get status => _status;

  @override
  Future<void> connect(String url) async {
    _status = ConnectionStatus.connecting;
    _mockStatusController.add(_status);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _status = ConnectionStatus.connected;
    _mockStatusController.add(_status);
    _mockEventController.add(const VoiceEvent(type: VoiceEventType.connected));
  }

  @override
  void disconnect() {
    _status = ConnectionStatus.disconnected;
    _mockStatusController.add(_status);
  }

  @override
  Future<void> reconnect(String url) async {
    disconnect();
    await connect(url);
  }

  @override
  void sendAudioChunk(Uint8List bytes, int sequence) {
    // Drop mock audio bytes
  }

  @override
  void sendAudioComplete(String language, {Map<String, dynamic>? context}) {
    // Simulate backend response pipeline
    _simulateBackendPipeline();
  }

  @override
  void sendEvent(VoiceEvent event) {
    // No-op
  }

  Future<void> _simulateBackendPipeline() async {
    // 1. Session acknowledged
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.sessionAcknowledged,
      payload: {'message': 'session ready'},
      language: 'en',
    ));

    // 2. Send transcribing status
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.transcribing,
      payload: {'status': 'transcribing'},
      language: 'en',
    ));

    // 3. Send partial transcript
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.partialTranscript,
      payload: {'text': 'I am testing the...'},
      language: 'en',
    ));

    // 4. Send final transcript
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.finalTranscript,
      payload: {'text': 'I am testing the mock integration pipeline.'},
      language: 'en',
    ));

    // 5. Send assistant thinking / response chunks
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.thinking,
      payload: {'status': 'thinking'},
      language: 'en',
    ));

    await Future<void>.delayed(const Duration(milliseconds: 800));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.responseChunk,
      payload: {
        'text': 'This is a mock response from the simulated backend.'
      },
      language: 'en',
    ));

    await Future<void>.delayed(const Duration(milliseconds: 400));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.responseComplete,
      payload: {},
      language: 'en',
    ));

    // 6. Generate audio
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.generatingAudio,
      payload: {'status': 'generating_audio'},
      language: 'en',
    ));

    // 7. Send mock audio chunks
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockEventController.add(VoiceEvent(
      type: VoiceEventType.audioChunk,
      payload: {'audio': base64Encode(Uint8List(0))},
      language: 'en',
    ));

    await Future<void>.delayed(const Duration(milliseconds: 250));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.audioComplete,
      payload: {'status': 'audio_complete'},
      language: 'en',
    ));
  }

  @override
  void dispose() {
    _mockEventController.close();
    _mockStatusController.close();
    super.dispose();
  }
}

/// A harness screen that wraps the normal VoiceTutorScreen but injects
/// a mock backend connection.
class VoiceIntegrationScreen extends StatelessWidget {
  const VoiceIntegrationScreen({
    super.key,
    required this.languageProvider,
  });

  final LanguageProvider languageProvider;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        voiceConnectionProvider.overrideWith((ref) {
          final notifier = VoiceConnectionNotifier(
            socketService: MockVoiceSocketService(),
          );
          // Auto-connect to mock
          notifier.connect('ws://mock');
          return notifier;
        }),
      ],
      child: VoiceTutorScreen(
        languageProvider: languageProvider,
      ),
    );
  }
}
