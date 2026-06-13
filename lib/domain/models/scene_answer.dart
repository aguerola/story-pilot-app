import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/ai_usage.dart';

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

  AiUsage get usage => AiUsage(
        promptTokens: promptTokens,
        responseTokens: responseTokens,
        thoughtsTokens: thoughtsTokens,
        totalTokens: totalTokens,
        modelId: modelId,
      );

  bool get hasTokenUsage => usage.hasTokens;

  String get tokenUsageLabel => usage.tokenLabel;

  double? get estimatedCostUsd => usage.estimatedCostUsd;

  String? get costLabel => usage.costLabel;

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
