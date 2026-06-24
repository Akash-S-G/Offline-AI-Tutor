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
    // 1. Send partial transcript
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.partialTranscript,
      payload: {'text': 'I am testing the...'},
    ));

    // 2. Send final transcript
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.finalTranscript,
      payload: {'text': 'I am testing the mock integration pipeline.'},
    ));

    // 3. Send assistant reply text
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _mockEventController.add(const VoiceEvent(
      type: VoiceEventType.assistantMessage,
      payload: {
        'text': 'This is a mock response from the simulated backend.',
        'language': 'en'
      },
    ));

    // 4. Send mock audio chunks
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // We send a small valid WAV header so the player doesn't crash, 
    // or we can just send empty bytes if the player handles it gracefully.
    // For simplicity, we send empty bytes in this mock, but ideally a valid 
    // empty WAV or silent WAV. We'll send an empty list.
    _mockEventController.add(VoiceEvent(
      type: VoiceEventType.audioChunk,
      payload: {'audio': base64Encode(Uint8List(0))},
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
