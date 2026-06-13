import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/crew_member.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/title_summary.dart';

class TitleDetail extends Equatable {
  const TitleDetail({
    required this.summary,
    required this.overview,
    this.runtimeMinutes,
    this.seasons,
    required this.cast,
    this.tagline,
    this.genres = const [],
    this.status,
    this.originalTitle,
    this.originalLanguage,
    this.rating,
    this.voteCount,
    this.popularity,
    this.backdropUrl,
    this.homepage,
    this.imdbId,
    this.spokenLanguages = const [],
    this.countries = const [],
    this.releaseDate,
    this.firstAirDate,
    this.lastAirDate,
    this.budget,
    this.revenue,
    this.collectionName,
    this.createdBy = const [],
    this.networks = const [],
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.inProduction,
    this.crew = const [],
    this.keywords = const [],
  });

  final TitleSummary summary;
  final String overview;
  final int? runtimeMinutes;
  final List<Season>? seasons;
  final List<CastMember> cast;
  final String? tagline;
  final List<String> genres;
  final String? status;
  final String? originalTitle;
  final String? originalLanguage;
  final double? rating;
  final int? voteCount;
  final double? popularity;
  final String? backdropUrl;
  final String? homepage;
  final String? imdbId;
  final List<String> spokenLanguages;
  final List<String> countries;
  final String? releaseDate;
  final String? firstAirDate;
  final String? lastAirDate;
  final int? budget;
  final int? revenue;
  final String? collectionName;
  final List<String> createdBy;
  final List<String> networks;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final bool? inProduction;
  final List<CrewMember> crew;
  final List<String> keywords;

  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'overview': overview,
        'runtimeMinutes': runtimeMinutes,
        'seasons': seasons?.map((s) => s.toJson()).toList(),
        'cast': cast.map((c) => c.toJson()).toList(),
        'tagline': tagline,
        'genres': genres,
        'status': status,
        'originalTitle': originalTitle,
        'originalLanguage': originalLanguage,
        'rating': rating,
        'voteCount': voteCount,
        'popularity': popularity,
        'backdropUrl': backdropUrl,
        'homepage': homepage,
        'imdbId': imdbId,
        'spokenLanguages': spokenLanguages,
        'countries': countries,
        'releaseDate': releaseDate,
        'firstAirDate': firstAirDate,
        'lastAirDate': lastAirDate,
        'budget': budget,
        'revenue': revenue,
        'collectionName': collectionName,
        'createdBy': createdBy,
        'networks': networks,
        'numberOfSeasons': numberOfSeasons,
        'numberOfEpisodes': numberOfEpisodes,
        'inProduction': inProduction,
        'crew': crew.map((c) => c.toJson()).toList(),
        'keywords': keywords,
        'cachedAt': DateTime.now().toIso8601String(),
      };

  factory TitleDetail.fromJson(Map<String, dynamic> json) => TitleDetail(
        summary: TitleSummary.fromJson(json['summary'] as Map<String, dynamic>),
        overview: json['overview'] as String? ?? '',
        runtimeMinutes: json['runtimeMinutes'] as int?,
        seasons: (json['seasons'] as List<dynamic>?)
            ?.map((s) => Season.fromJson(s as Map<String, dynamic>))
            .toList(),
        cast: (json['cast'] as List<dynamic>)
            .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
            .toList(),
        tagline: json['tagline'] as String?,
        genres: (json['genres'] as List<dynamic>?)
                ?.map((g) => g as String)
                .toList() ??
            const [],
        status: json['status'] as String?,
        originalTitle: json['originalTitle'] as String?,
        originalLanguage: json['originalLanguage'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        voteCount: json['voteCount'] as int?,
        popularity: (json['popularity'] as num?)?.toDouble(),
        backdropUrl: json['backdropUrl'] as String?,
        homepage: json['homepage'] as String?,
        imdbId: json['imdbId'] as String?,
        spokenLanguages: (json['spokenLanguages'] as List<dynamic>?)
                ?.map((l) => l as String)
                .toList() ??
            const [],
        countries: (json['countries'] as List<dynamic>?)
                ?.map((c) => c as String)
                .toList() ??
            const [],
        releaseDate: json['releaseDate'] as String?,
        firstAirDate: json['firstAirDate'] as String?,
        lastAirDate: json['lastAirDate'] as String?,
        budget: json['budget'] as int?,
        revenue: json['revenue'] as int?,
        collectionName: json['collectionName'] as String?,
        createdBy: (json['createdBy'] as List<dynamic>?)
                ?.map((n) => n as String)
                .toList() ??
            const [],
        networks: (json['networks'] as List<dynamic>?)
                ?.map((n) => n as String)
                .toList() ??
            const [],
        numberOfSeasons: json['numberOfSeasons'] as int?,
        numberOfEpisodes: json['numberOfEpisodes'] as int?,
        inProduction: json['inProduction'] as bool?,
        crew: (json['crew'] as List<dynamic>?)
                ?.map((c) => CrewMember.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        keywords: (json['keywords'] as List<dynamic>?)
                ?.map((k) => k as String)
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        summary,
        overview,
        runtimeMinutes,
        seasons,
        cast,
        tagline,
        genres,
        status,
        originalTitle,
        originalLanguage,
        rating,
        voteCount,
        popularity,
        backdropUrl,
        homepage,
        imdbId,
        spokenLanguages,
        countries,
        releaseDate,
        firstAirDate,
        lastAirDate,
        budget,
        revenue,
        collectionName,
        createdBy,
        networks,
        numberOfSeasons,
        numberOfEpisodes,
        inProduction,
        crew,
        keywords,
      ];
}
