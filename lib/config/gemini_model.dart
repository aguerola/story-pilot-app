/// Supported Gemini models for scene AI (server-side via Cloud Functions).
/// Source: https://ai.google.dev/gemini-api/docs/pricing (Standard tier, paid)
enum GeminiModel {
  flashLite31(
    id: 'gemini-3.1-flash-lite',
    inputPerMillionUsd: 0.25,
    outputPerMillionUsd: 1.50,
  ),
  flashLite25(
    id: 'gemini-2.5-flash-lite',
    inputPerMillionUsd: 0.10,
    outputPerMillionUsd: 0.40,
  ),
  flash25(
    id: 'gemini-2.5-flash',
    inputPerMillionUsd: 0.30,
    outputPerMillionUsd: 2.50,
  );

  const GeminiModel({
    required this.id,
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
  });

  final String id;
  final double inputPerMillionUsd;
  final double outputPerMillionUsd;

  String get shortLabel => switch (this) {
        flashLite31 => 'Lite 3.1',
        flashLite25 => 'Lite 2.5',
        flash25 => 'Flash',
      };

  static const tierLabel = 'Standard';
  static const defaultModel = flashLite25;

  static GeminiModel fromId(String id) {
    for (final model in values) {
      if (model.id == id) return model;
    }
    return defaultModel;
  }

  /// Output billing includes response + thinking tokens per Google pricing.
  double? estimateCostUsd({
    int? promptTokens,
    int? responseTokens,
    int? thoughtsTokens,
  }) {
    if (promptTokens == null &&
        responseTokens == null &&
        thoughtsTokens == null) {
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
