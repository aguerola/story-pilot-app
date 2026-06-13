/// Pricing for Gemini models via Google AI / Firebase AI.
/// Source: https://ai.google.dev/gemini-api/docs/pricing (Standard tier, paid)
class GeminiPricing {
  const GeminiPricing({
    required this.modelId,
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
    required this.tierLabel,
  });

  final String modelId;
  final double inputPerMillionUsd;
  final double outputPerMillionUsd;
  final String tierLabel;

  /// gemini-2.5-flash — Standard paid tier (text input / output incl. thinking).
  static const flash25 = GeminiPricing(
    modelId: 'gemini-2.5-flash',
    inputPerMillionUsd: 0.30,
    outputPerMillionUsd: 2.50,
    tierLabel: 'Standard',
  );

  static GeminiPricing forModel(String modelId) {
    switch (modelId) {
      case 'gemini-2.5-flash':
        return flash25;
      default:
        return flash25;
    }
  }

  /// Output billing includes response + thinking tokens per Google pricing.
  double? estimateCostUsd({
    int? promptTokens,
    int? responseTokens,
    int? thoughtsTokens,
  }) {
    if (promptTokens == null && responseTokens == null && thoughtsTokens == null) {
      return null;
    }

    final inputCost = (promptTokens ?? 0) * inputPerMillionUsd / 1e6;
    final outputTokenCount = (responseTokens ?? 0) + (thoughtsTokens ?? 0);
    final outputCost = outputTokenCount * outputPerMillionUsd / 1e6;
    return inputCost + outputCost;
  }

  static String formatUsd(double amount) {
    if (amount < 0.0001) return '<\$0.0001';
    if (amount < 0.01) return '\$${amount.toStringAsFixed(4)}';
    return '\$${amount.toStringAsFixed(3)}';
  }
}
