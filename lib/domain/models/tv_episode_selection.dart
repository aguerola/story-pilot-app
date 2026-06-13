import 'package:equatable/equatable.dart';

class TvEpisodeSelection extends Equatable {
  const TvEpisodeSelection({
    required this.seasonNumber,
    required this.episodeNumber,
  });

  final int seasonNumber;
  final int episodeNumber;

  @override
  List<Object?> get props => [seasonNumber, episodeNumber];
}
