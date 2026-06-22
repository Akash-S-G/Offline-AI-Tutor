import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/models/voice_state.dart';
import '../../voice/providers/voice_provider.dart';

/// Extra-large mic button for primary school students (~2x normal size).
///
/// Same state animations as [MicButton] but sized for small children
/// with prominent press affordance.
class HugeMicButton extends ConsumerWidget {
  const HugeMicButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);

    return GestureDetector(
      onTap: () => _handleTap(voice.state, notifier),
      child: _HugeMicVisual(state: voice.state),
    );
  }

  void _handleTap(VoiceState state, VoiceNotifier notifier) {
    switch (state) {
      case VoiceState.idle:
        notifier.startRecording();
      case VoiceState.listening:
        notifier.stopRecording();
      case VoiceState.speaking:
        notifier.stopPlayback();
      case VoiceState.processing:
      case VoiceState.error:
        break;
    }
  }
}

class _HugeMicVisual extends StatefulWidget {
  const _HugeMicVisual({required this.state});

  final VoiceState state;

  @override
  State<_HugeMicVisual> createState() => _HugeMicVisualState();
}

class _HugeMicVisualState extends State<_HugeMicVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_HugeMicVisual old) {
    super.didUpdateWidget(old);
    if (widget.state == VoiceState.listening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state == VoiceState.listening;
    final isProcessing = widget.state == VoiceState.processing;
    final color = isRecording ? Colors.red : Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: isRecording ? _pulse.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: isRecording ? 30 : 12,
                  spreadRadius: isRecording ? 8 : 2,
                ),
              ],
            ),
            child: isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                : Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
          ),
        );
      },
    );
  }
}
