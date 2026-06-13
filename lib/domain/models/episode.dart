import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  const Episode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.airDate,
    this.stillUrl,
    this.runtimeMinutes,
  });

  final int episodeNumber;
  final String name;
  final String? overview;
  final String? airDate;
  final String? stillUrl;
  final int? runtimeMinutes;

  @override
  List<Object?> get props =>
      [episodeNumber, name, overview, airDate, stillUrl, runtimeMinutes];
}
