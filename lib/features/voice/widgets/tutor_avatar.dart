import 'package:flutter/material.dart';

import '../../tutor/models/conversation_state.dart';

/// Animated tutor avatar that responds to [ConversationState].
///
/// States:
/// - **idle**: gentle breathing (scale pulse)
/// - **listening**: blue glow ring with pulse
/// - **uploading**: uploading indicator
/// - **thinking**: orbiting dots/pulse
/// - **speaking**: equalizer bars placeholder
class TutorAvatar extends StatefulWidget {
  const TutorAvatar({
    super.key,
    required this.state,
    this.size = 120,
  });

  final ConversationState state;
  final double size;

  @override
  State<TutorAvatar> createState() => _TutorAvatarState();
}

class _TutorAvatarState extends State<TutorAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breathe = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIdle = widget.state == ConversationState.idle;
    final isListening = widget.state == ConversationState.listening;
    final isProcessing = _isProcessing(widget.state);
    final isSpeaking = widget.state == ConversationState.speaking;
    final isUploading = widget.state == ConversationState.uploading;

    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        return Transform.scale(
          scale: isIdle || isListening ? _breathe.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _glowColor(widget.state, theme).withAlpha(180),
                  _glowColor(widget.state, theme).withAlpha(60),
                ],
              ),
              boxShadow: [
                if (isListening || isSpeaking)
                  BoxShadow(
                    color: _glowColor(widget.state, theme).withAlpha(100),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.school_rounded,
                  size: widget.size * 0.45,
                  color: Colors.white,
                ),
                if (isUploading)
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                if (isProcessing && !isUploading)
                  SizedBox(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    child: CircularProgressIndicator(
                      color: Colors.white.withAlpha(150),
                      strokeWidth: 2,
                    ),
                  ),
                if (isSpeaking)
                  Positioned(
                    bottom: widget.size * 0.15,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 8 + (index % 2 == 0 ? 8 : 4) * _breathe.value,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isProcessing(ConversationState state) {
    return state == ConversationState.uploading ||
        state == ConversationState.transcribing ||
        state == ConversationState.translating ||
        state == ConversationState.thinking ||
        state == ConversationState.generatingAudio;
  }

  Color _glowColor(ConversationState state, ThemeData theme) {
    if (state == ConversationState.idle) return theme.colorScheme.primary;
    if (state == ConversationState.listening) return Colors.blue;
    if (_isProcessing(state)) return Colors.amber.shade700;
    if (state == ConversationState.speaking) return Colors.green;
    return Colors.red;
  }
}
