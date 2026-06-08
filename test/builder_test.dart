import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/experiment/builder/validation/builder_validation_test.dart';

void main() {
  test('Builder Validation Test Runs', () async {
    final testRunner = BuilderValidationTest();
    await testRunner.runTest();
  });
}
