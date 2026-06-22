import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:offline_tutor_app/features/language/models/app_language.dart';
import 'package:offline_tutor_app/features/language/providers/language_provider.dart';
import 'package:offline_tutor_app/features/language/widgets/language_selector.dart';
import 'package:offline_tutor_app/features/tutor/screens/primary_voice_tutor_screen.dart';
import 'package:offline_tutor_app/features/tutor/widgets/huge_mic_button.dart';
import 'package:offline_tutor_app/features/tutor/widgets/large_response_card.dart';
import 'package:offline_tutor_app/features/voice/widgets/tutor_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('PrimaryVoiceTutorScreen renders expected simplified widgets', (tester) async {
    final languageProvider = LanguageProvider();

    await tester.pumpWidget(wrap(PrimaryVoiceTutorScreen(
      languageProvider: languageProvider,
    )));

    expect(find.byType(TutorAvatar), findsOneWidget);
    expect(find.byType(LargeResponseCard), findsOneWidget);
    expect(find.byType(HugeMicButton), findsOneWidget);
    expect(find.byType(LanguageSelector), findsOneWidget);

    // Should contain the placeholder text initially
    expect(find.text('Tap the mic to ask a question!'), findsOneWidget);
  });
}
