import 'package:equatable/equatable.dart';

sealed class SceneEvent extends Equatable {
  const SceneEvent();

  @override
  List<Object?> get props => [];
}

final class SceneStarted extends SceneEvent {
  const SceneStarted({
    required this.tmdbId,
    this.initialTimestampMs = 0,
    this.seasonNumber,
    this.episodeNumber,
  });

  final int tmdbId;
  final int initialTimestampMs;
  final int? seasonNumber;
  final int? episodeNumber;

  @override
  List<Object?> get props =>
      [tmdbId, initialTimestampMs, seasonNumber, episodeNumber];
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

final class TimestampChanged extends SceneEvent {
  const TimestampChanged(this.timestampMs);

  final int timestampMs;

  @override
  List<Object?> get props => [timestampMs];
}
