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
    this.usedBreakdown,
  });

  final int? promptTokens;
  final int? responseTokens;
  final int? thoughtsTokens;
  final int? totalTokens;
  final String? modelId;
  /// Whether the server used AI scene-breakdown context (vs subtitles only).
  final bool? usedBreakdown;

  bool get hasTokens =>
      promptTokens != null ||
      responseTokens != null ||
      thoughtsTokens != null ||
      totalTokens != null;

  bool get hasDebugInfo => hasTokens || usedBreakdown != null;

  String? get contextLabel {
    if (usedBreakdown == null) return null;
    return usedBreakdown!
        ? 'Contexto: preprocesado (breakdown)'
        : 'Contexto: subtítulos';
  }

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
  List<Object?> get props => [
        promptTokens,
        responseTokens,
        thoughtsTokens,
        totalTokens,
        modelId,
        usedBreakdown,
      ];
}
