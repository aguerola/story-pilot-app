import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/scene_breakdown.dart';

enum TitlePreprocessingStatus { pending, ready }

class TitlePreprocessingResult extends Equatable {
  const TitlePreprocessingResult({
    required this.status,
    this.breakdown,
  });

  const TitlePreprocessingResult.pending()
      : status = TitlePreprocessingStatus.pending,
        breakdown = null;

  const TitlePreprocessingResult.ready({
    required this.breakdown,
  }) : status = TitlePreprocessingStatus.ready;

  final TitlePreprocessingStatus status;
  final TitleBreakdown? breakdown;

  bool get isReady => status == TitlePreprocessingStatus.ready;

  bool get isPending => status == TitlePreprocessingStatus.pending;

  int? get durationMs => breakdown?.durationMs;

  @override
  List<Object?> get props => [status, breakdown];
}
