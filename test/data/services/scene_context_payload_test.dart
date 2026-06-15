import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';

void main() {
  test('toAskPayload includes only anti-spoiler fields', () {
    const context = SceneContext(
      timestampMs: 3661000,
      sceneBeforeSeconds: 120,
      sceneAfterSeconds: 30,
      activeLine: null,
      dialogueText: 'Final de la escena.',
      askDialogueText: 'Inicio\nMitad\nFinal de la escena.',
      priorDialogueText: 'Inicio\nMitad',
      followingDialogueText: 'Justo después',
      titleLabel: 'Matrix (1999)',
      characters: [],
    );

    final payload = context.toAskPayload();

    expect(payload['timestampMs'], 3661000);
    expect(payload['priorDialogueText'], 'Inicio\nMitad');
    expect(payload['titleLabel'], 'Matrix (1999)');
    expect(payload.containsKey('followingDialogueText'), isFalse);
    expect(payload.containsKey('dialogueText'), isFalse);
    expect(payload.containsKey('askDialogueText'), isFalse);
    expect(payload['priorDialogueText'], isNot(contains('Justo después')));
  });

  test('SceneAnswer tokenUsageLabel formats usage counts', () {
    const answer = SceneAnswer(
      question: '¿Quién está?',
      answer: 'Neo',
      promptTokens: 346,
      responseTokens: 218,
      thoughtsTokens: 590,
      totalTokens: 1154,
    );

    expect(answer.hasTokenUsage, isTrue);
    expect(
      answer.tokenUsageLabel,
      '346 prompt · 218 respuesta · 590 razonamiento · 1154 total',
    );
  });

  test('SceneAnswer tokenUsageLabel omits zero thoughts', () {
    const answer = SceneAnswer(
      question: '¿Quién está?',
      answer: 'Neo',
      promptTokens: 100,
      responseTokens: 50,
      thoughtsTokens: 0,
      totalTokens: 150,
    );

    expect(answer.tokenUsageLabel, '100 prompt · 50 respuesta · 150 total');
  });

  test('SceneAnswer hasTokenUsage is false without counts', () {
    const answer = SceneAnswer(
      question: '¿Quién está?',
      answer: 'Neo',
    );

    expect(answer.hasTokenUsage, isFalse);
    expect(answer.tokenUsageLabel, isEmpty);
  });
}
