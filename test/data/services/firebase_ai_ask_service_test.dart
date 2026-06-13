import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/data/services/firebase_ai_ask_service.dart';
import 'package:storypilot/domain/models/scene_context.dart';

void main() {
  test('buildAskPromptContent includes dialogue and question', () {
    const context = SceneContext(
      timestampMs: 1000,
      windowSeconds: 30,
      dialogueText: 'Neo: I know kung fu.',
      characters: [],
    );

    final content = buildAskPromptContent(context, '¿Qué pasa?');

    expect(content, contains('Neo: I know kung fu.'));
    expect(content, contains('¿Qué pasa?'));
    expect(content, contains('Personajes detectados'));
  });
}
