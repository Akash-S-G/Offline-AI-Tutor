import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/chat/application/simple_ai_chat_component.dart';

void main() {
  group('SimpleAiChatComponent', () {
    const component = SimpleAiChatComponent();

    test('does not treat a real question starting with hi as a greeting', () {
      expect(
        component.localFastReply(question: 'hi explain this chapter'),
        isNull,
      );
    });

    test('still handles standalone greetings', () {
      expect(
        component.localFastReply(question: 'hi'),
        isNotNull,
      );
    });

    test('handles greeting with punctuation only', () {
      expect(
        component.localFastReply(question: 'hello!'),
        isNotNull,
      );
    });
  });
}
