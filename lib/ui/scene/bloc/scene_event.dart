import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/media_type.dart';

sealed class SceneEvent extends Equatable {
  const SceneEvent();

  @override
  List<Object?> get props => [];
}

final class SceneStarted extends SceneEvent {
  const SceneStarted({
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
  });

  final int tmdbId;
  final MediaType mediaType;
  final int? seasonNumber;
  final int? episodeNumber;

  @override
  List<Object?> get props =>
      [tmdbId, mediaType, seasonNumber, episodeNumber];
}

final class EpisodeSelected extends SceneEvent {
  const EpisodeSelected({
    required this.seasonNumber,
    required this.episodeNumber,
  });

  final int seasonNumber;
  final int episodeNumber;

  @override
  List<Object?> get props => [seasonNumber, episodeNumber];
}

/// Updates preprocessed scene info immediately while scrubbing the timeline.
final class TimestampScrubbed extends SceneEvent {
  const TimestampScrubbed(this.timestampMs);

  final int timestampMs;

  @override
  List<Object?> get props => [timestampMs];
}

/// Commits the timestamp and loads AI brief + suggested questions (debounced).
final class TimestampChanged extends SceneEvent {
  const TimestampChanged(this.timestampMs);

  final int timestampMs;

  @override
  List<Object?> get props => [timestampMs];
}

final class PreprocessingRetry extends SceneEvent {
  const PreprocessingRetry();
}
