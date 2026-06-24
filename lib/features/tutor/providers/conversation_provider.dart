import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../language/models/app_language.dart';
import '../../simulation_context/providers/simulation_context_provider.dart';
import '../../voice/models/voice_event.dart';
import '../../voice/providers/voice_connection_provider.dart';
import '../../voice/providers/voice_provider.dart';
import '../models/conversation_message.dart';
import '../models/conversation_state.dart';

import '../../voice/services/voice_stream_player.dart';

// ─── State ──────────────────────────────────────────────────────────

class ConversationProviderState {
  const ConversationProviderState({
    this.state = ConversationState.idle,
    this.messages = const [],
    this.partialTranscript = '',
    this.finalTranscript = '',
    this.responseLatency = Duration.zero,
  });

  final ConversationState state;
  final List<ConversationMessage> messages;
  final String partialTranscript;
  final String finalTranscript;
  final Duration responseLatency;

  ConversationProviderState copyWith({
    ConversationState? state,
    List<ConversationMessage>? messages,
    String? partialTranscript,
    String? finalTranscript,
    Duration? responseLatency,
  }) {
    return ConversationProviderState(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      finalTranscript: finalTranscript ?? this.finalTranscript,
      responseLatency: responseLatency ?? this.responseLatency,
    );
  }
}
// ─── Notifier ───────────────────────────────────────────────────────

class ConversationNotifier extends StateNotifier<ConversationProviderState> {
  ConversationNotifier({required this.ref})
      : super(const ConversationProviderState());

  final Ref ref;
  final VoiceStreamPlayer _streamPlayer = VoiceStreamPlayer();
  StreamSubscription<VoiceEvent>? _eventSub;
  DateTime? _requestTimestamp;
  int _messageCounter = 0;

  /// Start listening to voice events from the socket.
  void attachToSocket() {
    final socket = ref.read(voiceConnectionProvider.notifier).socket;
    _eventSub?.cancel();
    _eventSub = socket.eventStream.listen(_onVoiceEvent);
  }

  // ─── Public API ─────────────────────────────────────────────────

  /// Start a new conversation turn: begin recording.
  Future<void> startListening() async {
    await _streamPlayer.interrupt(); // Instantly stop any ongoing playback
    state = state.copyWith(
      state: ConversationState.listening,
      partialTranscript: '',
      finalTranscript: '',
    );
    await ref.read(voiceProvider.notifier).startRecording();
  }

  /// Stop recording and send audio to server.
  Future<void> stopListeningAndSend() async {
    state = state.copyWith(state: ConversationState.uploading);
    _requestTimestamp = DateTime.now();
    await ref.read(voiceProvider.notifier).stopRecording();

    // Signal audio complete to server with current simulation context
    final socket = ref.read(voiceConnectionProvider.notifier).socket;
    final context = ref.read(simulationContextProvider);
    socket.sendAudioComplete('en', context: context.hasContext ? context.toJson() : null);

    state = state.copyWith(state: ConversationState.transcribing);
  }

  /// Handle a transcript received from server.
  void onTranscriptReceived(String text, {required bool isFinal}) {
    if (isFinal) {
      state = state.copyWith(
        finalTranscript: text,
        partialTranscript: '',
      );
    } else {
      state = state.copyWith(partialTranscript: text);
    }
  }

  /// Handle tutor response text from server.
  void onAssistantResponse(String text, AppLanguage language) {
    final latency = _requestTimestamp != null
        ? DateTime.now().difference(_requestTimestamp!)
        : Duration.zero;

    final message = ConversationMessage(
      id: 'msg_${++_messageCounter}',
      role: MessageRole.assistant,
      text: text,
      language: language,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      state: ConversationState.speaking,
      messages: [...state.messages, message],
      responseLatency: latency,
    );
  }

  /// Called when tutor audio playback finishes.
  void onSpeakingComplete() {
    state = state.copyWith(state: ConversationState.idle);
  }

  /// Add a student message to the history.
  void addStudentMessage(String text, AppLanguage language) {
    final message = ConversationMessage(
      id: 'msg_${++_messageCounter}',
      role: MessageRole.student,
      text: text,
      language: language,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Clear all history and return to idle.
  void reset() {
    _streamPlayer.interrupt();
    state = const ConversationProviderState();
    _messageCounter = 0;
    _requestTimestamp = null;
  }

  // ─── Internal: voice event routing ──────────────────────────────

  void _onVoiceEvent(VoiceEvent event) {
    switch (event.type) {
      case VoiceEventType.partialTranscript:
        onTranscriptReceived(
          event.payload['text'] as String? ?? '',
          isFinal: false,
        );
      case VoiceEventType.finalTranscript:
        final text = event.payload['text'] as String? ?? '';
        onTranscriptReceived(text, isFinal: true);
        // Add student message to history
        addStudentMessage(text, AppLanguage.english); // Language resolved by server
        state = state.copyWith(state: ConversationState.translating);
      case VoiceEventType.assistantMessage:
        final text = event.payload['text'] as String? ?? '';
        final langCode = event.payload['language'] as String? ?? 'en';
        onAssistantResponse(text, AppLanguage.fromCode(langCode));
      case VoiceEventType.audioChunk:
        final base64Chunk = event.payload['audio'] as String?;
        if (base64Chunk != null) {
          _streamPlayer.queueAudioChunk(base64Chunk);
        }
        state = state.copyWith(state: ConversationState.speaking);
      case VoiceEventType.error:
        state = state.copyWith(state: ConversationState.error);
      default:
        break;
    }
  }

  @override
  void dispose() {
    _streamPlayer.dispose();
    _eventSub?.cancel();
    super.dispose();
  }
}

// ─── Provider ───────────────────────────────────────────────────────

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationProviderState>(
        (ref) {
  return ConversationNotifier(ref: ref);
});
