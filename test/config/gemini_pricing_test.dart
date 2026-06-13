import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/config/gemini_pricing.dart';
import 'package:storypilot/domain/models/scene_answer.dart';

void main() {
  group('GeminiPricing', () {
    test('estimates cost for gemini-2.5-flash standard tier', () {
      const pricing = GeminiPricing.flash25;

      final cost = pricing.estimateCostUsd(
        promptTokens: 346,
        responseTokens: 218,
        thoughtsTokens: 590,
      );

      // input: 346 * 0.30 / 1e6 = 0.0001038
      // output: (218 + 590) * 2.50 / 1e6 = 0.00202
      expect(cost, closeTo(0.0021238, 0.0000001));
    });

    test('formatUsd shows 4 decimals for small amounts', () {
      expect(GeminiPricing.formatUsd(0.0021238), '\$0.0021');
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
        modelId: 'gemini-2.5-flash',
      );

      expect(answer.costLabel, contains('USD'));
      expect(answer.costLabel, contains('gemini-2.5-flash'));
      expect(answer.costLabel, contains('Standard'));
      expect(answer.estimatedCostUsd, closeTo(0.0021238, 0.0000001));
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
