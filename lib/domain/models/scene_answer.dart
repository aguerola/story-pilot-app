import 'package:equatable/equatable.dart';
import 'package:storypilot/config/gemini_pricing.dart';

class SceneAnswer extends Equatable {
  const SceneAnswer({
    required this.question,
    required this.answer,
    this.sources = const [],
    this.promptTokens,
    this.responseTokens,
    this.thoughtsTokens,
    this.totalTokens,
    this.modelId,
  });

  final String question;
  final String answer;
  final List<String> sources;
  final int? promptTokens;
  final int? responseTokens;
  final int? thoughtsTokens;
  final int? totalTokens;
  final String? modelId;

  bool get hasTokenUsage =>
      promptTokens != null ||
      responseTokens != null ||
      thoughtsTokens != null ||
      totalTokens != null;

  String get tokenUsageLabel {
    final parts = <String>[];
    if (promptTokens != null) parts.add('$promptTokens prompt');
    if (responseTokens != null) parts.add('$responseTokens respuesta');
    if (thoughtsTokens != null && thoughtsTokens! > 0) {
      parts.add('$thoughtsTokens razonamiento');
    }
    if (totalTokens != null) parts.add('$totalTokens total');
    return parts.join(' · ');
  }

  double? get estimatedCostUsd {
    if (modelId == null) return null;
    return GeminiPricing.forModel(modelId!).estimateCostUsd(
      promptTokens: promptTokens,
      responseTokens: responseTokens,
      thoughtsTokens: thoughtsTokens,
    );
  }

  String? get costLabel {
    final cost = estimatedCostUsd;
    if (cost == null || modelId == null) return null;
    final pricing = GeminiPricing.forModel(modelId!);
    return '${GeminiPricing.formatUsd(cost)} USD '
        '(${pricing.modelId}, ${pricing.tierLabel})';
  }

  @override
  List<Object?> get props => [
        question,
        answer,
        sources,
        promptTokens,
        responseTokens,
        thoughtsTokens,
        totalTokens,
        modelId,
      ];
}
