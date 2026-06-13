import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/domain/models/scene_answer.dart';

void main() {
  group('GeminiModel', () {
    test('lists all supported models', () {
      expect(
        GeminiModel.values.map((m) => m.id).toList(),
        [
          'gemini-3.1-flash-lite',
          'gemini-2.5-flash-lite',
          'gemini-2.5-flash',
        ],
      );
    });

    test('fromId resolves known models', () {
      expect(
        GeminiModel.fromId('gemini-3.1-flash-lite').id,
        'gemini-3.1-flash-lite',
      );
      expect(
        GeminiModel.fromId('gemini-2.5-flash').id,
        'gemini-2.5-flash',
      );
      expect(
        GeminiModel.fromId('gemini-2.5-flash-lite').id,
        'gemini-2.5-flash-lite',
      );
    });

    test('fromId falls back to default for unknown ids', () {
      expect(GeminiModel.fromId('unknown').id, GeminiModel.defaultModel.id);
    });

    test('estimates cost for gemini-3.1-flash-lite standard tier', () {
      const model = GeminiModel.flashLite31;

      final cost = model.estimateCostUsd(
        promptTokens: 346,
        responseTokens: 218,
        thoughtsTokens: 590,
      );

      // input: 346 * 0.25 / 1e6 = 0.0000865
      // output: (218 + 590) * 1.50 / 1e6 = 0.001212
      expect(cost, closeTo(0.0012985, 0.0000001));
    });

    test('estimates cost for gemini-2.5-flash-lite standard tier', () {
      const model = GeminiModel.flashLite25;

      final cost = model.estimateCostUsd(
        promptTokens: 346,
        responseTokens: 218,
        thoughtsTokens: 590,
      );

      // input: 346 * 0.10 / 1e6 = 0.0000346
      // output: (218 + 590) * 0.40 / 1e6 = 0.0003232
      expect(cost, closeTo(0.0003578, 0.0000001));
    });

    test('estimates cost for gemini-2.5-flash standard tier', () {
      const model = GeminiModel.flash25;

      final cost = model.estimateCostUsd(
        promptTokens: 346,
        responseTokens: 218,
        thoughtsTokens: 590,
      );

      // input: 346 * 0.30 / 1e6 = 0.0001038
      // output: (218 + 590) * 2.50 / 1e6 = 0.00202
      expect(cost, closeTo(0.0021238, 0.0000001));
    });

    test('formatUsd shows 4 decimals for small amounts', () {
      expect(GeminiModel.formatUsd(0.0021238), '\$0.0021');
    });
  });

  group('SceneAnswer cost', () {
    test('costLabel includes model and tier', () {
      const answer = SceneAnswer(
        question: 'q',
        answer: 'a',
        promptTokens: 346,
        responseTokens: 218,
        thoughtsTokens: 590,
        totalTokens: 1154,
        modelId: 'gemini-2.5-flash-lite',
      );

      expect(answer.costLabel, contains('USD'));
      expect(answer.costLabel, contains('gemini-2.5-flash-lite'));
      expect(answer.costLabel, contains('Standard'));
      expect(answer.estimatedCostUsd, closeTo(0.0003578, 0.0000001));
    });

    test('costLabel is null without modelId', () {
      const answer = SceneAnswer(
        question: 'q',
        answer: 'a',
        promptTokens: 100,
        responseTokens: 50,
      );

      expect(answer.costLabel, isNull);
    });
  });
}
