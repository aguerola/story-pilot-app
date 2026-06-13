import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/data/services/firebase_ai_ask_service.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';

void main() {
  test('isQuotaExceeded detects quota errors', () {
    expect(
      isQuotaExceeded(ServerException('Quota exceeded for metric')),
      isTrue,
    );
    expect(
      isQuotaExceeded(ServerException('Network timeout')),
      isFalse,
    );
  });

  test('parseQuotaRetrySeconds extracts retry delay', () {
    expect(
      parseQuotaRetrySeconds(
        'Quota exceeded... Please retry in 54.155857482s.',
      ),
      55,
    );
    expect(parseQuotaRetrySeconds('Quota exceeded'), isNull);
  });

  test('quotaFailureMessage includes model and retry hint', () {
    expect(
      quotaFailureMessage(modelLabel: 'Flash', retryAfterSeconds: 55),
      contains('Flash'),
    );
    expect(
      quotaFailureMessage(modelLabel: 'Flash', retryAfterSeconds: 55),
      contains('55s'),
    );
    expect(
      quotaFailureMessage(modelLabel: 'Lite', retryAfterSeconds: null),
      contains('Lite'),
    );
  });

  test('buildAskPromptContent includes dialogue and question', () {
    const context = SceneContext(
      timestampMs: 3661000,
      sceneBeforeSeconds: 120,
      sceneAfterSeconds: 30,
      activeLine: null,
      dialogueText: 'Final de la escena.',
      askDialogueText: 'Inicio\nMitad\nFinal de la escena.',
      priorDialogueText: 'Inicio\nMitad',
      characters: [],
    );

    final content = buildAskPromptContent(context, '¿Qué pasa al final?');

    expect(content, contains('Momento seleccionado: 01:01:01'));
    expect(content, contains('Escena seleccionada'));
    expect(content, contains('2 min antes → 30s después'));
    expect(content, contains('Final de la escena.'));
    expect(content, contains('Contexto previo'));
    expect(content, contains('todos los subtítulos desde el inicio'));
    expect(content, contains('Inicio\nMitad'));
    expect(content, contains('¿Qué pasa al final?'));
    expect(content, contains('ESCENA SELECCIONADA'));
    expect(content, contains('Personajes detectados automáticamente'));
    expect(content, contains('lista incompleta'));
    expect(content, contains('complementa con tu conocimiento'));
    expect(content, contains('No spoilers'));
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
