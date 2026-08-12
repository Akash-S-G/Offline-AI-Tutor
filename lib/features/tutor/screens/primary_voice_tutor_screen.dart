import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../language/providers/language_provider.dart';
import '../../language/widgets/language_selector.dart';
import '../../language/services/language_interceptor.dart';
import '../../voice/providers/voice_connection_provider.dart';
import '../../voice/widgets/tutor_avatar.dart';
import '../models/conversation_message.dart';
import '../providers/conversation_provider.dart';
import '../widgets/huge_mic_button.dart';
import '../widgets/large_response_card.dart';

/// Primary-school-optimized voice tutor screen (F7).
///
/// Simplified layout for young children:
/// 1. Animated Tutor (40–50% screen height)
/// 2. Large Response Card (24–32px font)
/// 3. Huge Mic Button
/// 4. Language Selector
///
/// NO: chat history, debug info, developer data, advanced controls.
///
/// Interaction: Tap Mic → Speak → Listen → Repeat.
class PrimaryVoiceTutorScreen extends ConsumerStatefulWidget {
  const PrimaryVoiceTutorScreen({
    super.key,
    required this.languageProvider,
  });

  final LanguageProvider languageProvider;

  @override
  ConsumerState<PrimaryVoiceTutorScreen> createState() =>
      _PrimaryVoiceTutorScreenState();
}

class _PrimaryVoiceTutorScreenState
    extends ConsumerState<PrimaryVoiceTutorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final voiceConn = ref.read(voiceConnectionProvider.notifier);
        voiceConn.socket.interceptor ??=
            LanguageInterceptor(widget.languageProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.languageProvider,
      builder: (context, _) {
        final conv = ref.watch(conversationProvider);
        final screenHeight = MediaQuery.of(context).size.height;

        // Get the last tutor response for the response card
        final lastTutorResponse = conv.messages
            .where((m) => m.role == MessageRole.assistant)
            .lastOrNull
            ?.text ?? '';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 1. Animated Tutor (40–50% screen height)
                  SizedBox(
                    height: screenHeight * 0.40,
                    child: Center(
                      child: TutorAvatar(
                        state: conv.state,
                        size: screenHeight * 0.30,
                      ),
                    ),
                  ),

                  // 2. Large Response Card
                  LargeResponseCard(text: lastTutorResponse),

                  const SizedBox(height: 24), // Replaced Spacer

                  // 3. Huge Mic Button
                  HugeMicButton(languageCode: widget.languageProvider.languageCode),

                  const SizedBox(height: 20),

                  // 4. Language Selector (compact row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LanguageSelector(
                      languageProvider: widget.languageProvider,
                      compact: true,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
