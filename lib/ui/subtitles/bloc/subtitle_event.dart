import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_track.dart';

sealed class SubtitleEvent extends Equatable {
  const SubtitleEvent();

  @override
  List<Object?> get props => [];
}

final class SubtitleTracksRequested extends SubtitleEvent {
  const SubtitleTracksRequested({
    required this.tmdbId,
    required this.mediaType,
    this.language,
  });

  final int tmdbId;
  final MediaType mediaType;
  final String? language;

  @override
  List<Object?> get props => [tmdbId, mediaType, language];
}

final class SubtitleLanguageChanged extends SubtitleEvent {
  const SubtitleLanguageChanged(this.language);

  final String language;

  @override
  List<Object?> get props => [language];
}

final class SubtitleDownloadRequested extends SubtitleEvent {
  const SubtitleDownloadRequested({
    required this.tmdbId,
    required this.track,
  });

  final int tmdbId;
  final SubtitleTrack track;

  @override
  List<Object?> get props => [tmdbId, track];
}
