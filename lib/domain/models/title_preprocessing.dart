import 'package:equatable/equatable.dart';

enum TitlePreprocessingStatus { pending, ready }

class TitlePreprocessingResult extends Equatable {
  const TitlePreprocessingResult({
    required this.status,
    this.durationMs,
    this.titleLabel,
    this.sceneCount,
    this.analysisVersion,
    this.generatedAt,
  });

  const TitlePreprocessingResult.pending()
      : status = TitlePreprocessingStatus.pending,
        durationMs = null,
        titleLabel = null,
        sceneCount = null,
        analysisVersion = null,
        generatedAt = null;

  const TitlePreprocessingResult.ready({
    required this.durationMs,
    required this.titleLabel,
    required this.sceneCount,
    required this.analysisVersion,
    required this.generatedAt,
  }) : status = TitlePreprocessingStatus.ready;

  final TitlePreprocessingStatus status;
  final int? durationMs;
  final String? titleLabel;
  final int? sceneCount;
  final int? analysisVersion;
  final int? generatedAt;

  bool get isReady => status == TitlePreprocessingStatus.ready;

  bool get isPending => status == TitlePreprocessingStatus.pending;

  @override
  List<Object?> get props => [
        status,
        durationMs,
        titleLabel,
        sceneCount,
        analysisVersion,
        generatedAt,
      ];
}
