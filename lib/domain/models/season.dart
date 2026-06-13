import 'package:equatable/equatable.dart';

class Season extends Equatable {
  const Season({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.overview,
    this.airDate,
    this.posterUrl,
  });

  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? overview;
  final String? airDate;
  final String? posterUrl;

  Map<String, dynamic> toJson() => {
        'seasonNumber': seasonNumber,
        'name': name,
        'episodeCount': episodeCount,
        'overview': overview,
        'airDate': airDate,
        'posterUrl': posterUrl,
      };

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        seasonNumber: json['seasonNumber'] as int,
        name: json['name'] as String,
        episodeCount: json['episodeCount'] as int,
        overview: json['overview'] as String?,
        airDate: json['airDate'] as String?,
        posterUrl: json['posterUrl'] as String?,
      );

  @override
  List<Object?> get props =>
      [seasonNumber, name, episodeCount, overview, airDate, posterUrl];
}
