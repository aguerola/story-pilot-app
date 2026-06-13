import 'package:equatable/equatable.dart';
import 'package:storypilot/config/gemini_model.dart';

/// Token usage + estimated cost for a single AI call. Shown in debug builds for
/// any prompt we send (questions and the auto-brief).
class AiUsage extends Equatable {
  const AiUsage({
    this.promptTokens,
    this.responseTokens,
    this.thoughtsTokens,
    this.totalTokens,
    this.modelId,
  });

  final int? promptTokens;
  final int? responseTokens;
  final int? thoughtsTokens;
  final int? totalTokens;
  final String? modelId;

  bool get hasTokens =>
      promptTokens != null ||
      responseTokens != null ||
      thoughtsTokens != null ||
      totalTokens != null;

  String get tokenLabel {
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
    return GeminiModel.fromId(modelId!).estimateCostUsd(
      promptTokens: promptTokens,
      responseTokens: responseTokens,
      thoughtsTokens: thoughtsTokens,
    );
  }

  String? get costLabel {
    final cost = estimatedCostUsd;
    if (cost == null || modelId == null) return null;
    final model = GeminiModel.fromId(modelId!);
    return '${GeminiModel.formatUsd(cost)} USD '
        '(${model.id}, ${GeminiModel.tierLabel})';
  }

  @override
  List<Object?> get props =>
      [promptTokens, responseTokens, thoughtsTokens, totalTokens, modelId];
}
