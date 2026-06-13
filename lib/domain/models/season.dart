import 'package:equatable/equatable.dart';

class Season extends Equatable {
  const Season({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
  });

  final int seasonNumber;
  final String name;
  final int episodeCount;

  @override
  List<Object?> get props => [seasonNumber, name, episodeCount];
}
