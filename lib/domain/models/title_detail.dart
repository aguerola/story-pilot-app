import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/title_summary.dart';

class TitleDetail extends Equatable {
  const TitleDetail({
    required this.summary,
    required this.overview,
    this.runtimeMinutes,
    this.seasons,
    required this.cast,
  });

  final TitleSummary summary;
  final String overview;
  final int? runtimeMinutes;
  final List<Season>? seasons;
  final List<CastMember> cast;

  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'overview': overview,
        'runtimeMinutes': runtimeMinutes,
        'seasons': seasons
            ?.map(
              (s) => {
                'seasonNumber': s.seasonNumber,
                'name': s.name,
                'episodeCount': s.episodeCount,
              },
            )
            .toList(),
        'cast': cast.map((c) => c.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };

  factory TitleDetail.fromJson(Map<String, dynamic> json) => TitleDetail(
        summary: TitleSummary.fromJson(json['summary'] as Map<String, dynamic>),
        overview: json['overview'] as String? ?? '',
        runtimeMinutes: json['runtimeMinutes'] as int?,
        seasons: (json['seasons'] as List<dynamic>?)
            ?.map(
              (s) => Season(
                seasonNumber: s['seasonNumber'] as int,
                name: s['name'] as String,
                episodeCount: s['episodeCount'] as int,
              ),
            )
            .toList(),
        cast: (json['cast'] as List<dynamic>)
            .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props =>
      [summary, overview, runtimeMinutes, seasons, cast];
}
