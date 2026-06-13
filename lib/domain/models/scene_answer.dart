import 'package:equatable/equatable.dart';

class SceneAnswer extends Equatable {
  const SceneAnswer({
    required this.question,
    required this.answer,
    this.sources = const [],
    this.promptTokens,
    this.responseTokens,
    this.thoughtsTokens,
    this.totalTokens,
  });

  final String question;
  final String answer;
  final List<String> sources;
  final int? promptTokens;
  final int? responseTokens;
  final int? thoughtsTokens;
  final int? totalTokens;

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

  @override
  List<Object?> get props => [
        question,
        answer,
        sources,
        promptTokens,
        responseTokens,
        thoughtsTokens,
        totalTokens,
      ];
}
