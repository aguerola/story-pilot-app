import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/scene_context.dart';

sealed class SceneState extends Equatable {
  const SceneState();

  @override
  List<Object?> get props => [];
}

final class SceneInitial extends SceneState {
  const SceneInitial();
}

final class SceneLoading extends SceneState {
  const SceneLoading();
}

/// Scene metadata is ready but no moment is loaded yet: we wait for the user to
/// enter the moment they're watching instead of defaulting to 00:00:00.
final class SceneAwaitingTimestamp extends SceneState {
  const SceneAwaitingTimestamp();
}

/// TV show without a selected season/episode yet.
final class SceneAwaitingEpisode extends SceneState {
  const SceneAwaitingEpisode();
}

final class SceneLoaded extends SceneState {
  const SceneLoaded({
    required this.timestampMs,
    required this.context,
    required this.characters,
    this.summary,
    this.preprocessedSummary,
    this.questions = const [],
    this.briefUsage,
    this.briefError,
    this.isBriefLoading = false,
  });

  final int timestampMs;
  final SceneContext context;
  final List<SceneCharacter> characters;
  final String? summary;
  final String? preprocessedSummary;
  final List<String> questions;
  final AiUsage? briefUsage;
  final String? briefError;
  final bool isBriefLoading;

  String get displaySummary =>
      summary?.trim().isNotEmpty == true
          ? summary!.trim()
          : (preprocessedSummary ?? '');

  bool get isContextReady => !isBriefLoading;

  @override
  List<Object?> get props => [
        timestampMs,
        context,
        characters,
        summary,
        preprocessedSummary,
        questions,
        briefUsage,
        briefError,
        isBriefLoading,
      ];
}

final class SceneFailure extends SceneState {
  const SceneFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ScenePreprocessingFailure extends SceneState {
  const ScenePreprocessingFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
