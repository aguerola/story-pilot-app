import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_track.dart';

sealed class SubtitleState extends Equatable {
  const SubtitleState();

  @override
  List<Object?> get props => [];
}

final class SubtitleInitial extends SubtitleState {
  const SubtitleInitial();
}

final class SubtitleLoading extends SubtitleState {
  const SubtitleLoading();
}

final class SubtitleTracksLoaded extends SubtitleState {
  const SubtitleTracksLoaded({
    required this.tracks,
    required this.language,
  });

  final List<SubtitleTrack> tracks;
  final String language;

  @override
  List<Object?> get props => [tracks, language];
}

final class SubtitleDownloading extends SubtitleState {
  const SubtitleDownloading(this.track);

  final SubtitleTrack track;

  @override
  List<Object?> get props => [track];
}

final class SubtitleDownloaded extends SubtitleState {
  const SubtitleDownloaded(this.document);

  final SubtitleDocument document;

  @override
  List<Object?> get props => [document];
}

final class SubtitleFailure extends SubtitleState {
  const SubtitleFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
