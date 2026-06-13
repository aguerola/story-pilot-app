import 'package:dio/dio.dart';
import 'package:storypilot/config/env.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/crew_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';

class TmdbService {
  TmdbService(this._dio);

  final Dio _dio;

  static const _crewJobs = {
    'Director',
    'Writer',
    'Screenplay',
    'Novel',
    'Original Music Composer',
  };

  Future<Result<List<TitleSummary>>> search(String query) async {
    if (!Env.hasTmdbKey) {
      return const Error(NetworkFailure('TMDB_API_KEY not configured'));
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Env.wrapUrl('${Env.tmdbBaseUrl}/search/multi'),
        queryParameters: {
          'api_key': Env.tmdbApiKey,
          'query': query,
          'include_adult': false,
        },
      );
      final results = response.data?['results'] as List<dynamic>? ?? [];
      final summaries = results
          .whereType<Map<String, dynamic>>()
          .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
          .map(_mapSearchResult)
          .toList();
      return Success(summaries);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<TitleDetail>> fetchDetail(int id, MediaType type) async {
    if (!Env.hasTmdbKey) {
      return const Error(NetworkFailure('TMDB_API_KEY not configured'));
    }
    try {
      final path = type == MediaType.movie ? 'movie' : 'tv';
      final appendToResponse = type == MediaType.movie
          ? 'credits,keywords,external_ids'
          : 'aggregate_credits,keywords,external_ids';
      final detailResponse = await _dio.get<Map<String, dynamic>>(
        Env.wrapUrl('${Env.tmdbBaseUrl}/$path/$id'),
        queryParameters: {
          'api_key': Env.tmdbApiKey,
          'append_to_response': appendToResponse,
        },
      );
      final detail = detailResponse.data!;
      final creditsKey =
          type == MediaType.movie ? 'credits' : 'aggregate_credits';
      final credits = detail[creditsKey] as Map<String, dynamic>? ?? {};
      final summary = _mapDetailSummary(detail, type);
      final cast = _mapCast(credits, type);
      final crew = _mapCrew(credits);
      final keywords = _mapKeywords(detail['keywords'] as Map<String, dynamic>?);
      final externalIds =
          detail['external_ids'] as Map<String, dynamic>? ?? {};

      List<Season>? seasons;
      List<String> createdBy = const [];
      List<String> networks = const [];
      int? numberOfSeasons;
      int? numberOfEpisodes;
      bool? inProduction;
      String? firstAirDate;
      String? lastAirDate;

      if (type == MediaType.tv) {
        seasons = _mapSeasons(detail['seasons'] as List<dynamic>?);
        createdBy = _mapCreatedBy(detail['created_by'] as List<dynamic>?);
        networks = _mapNetworks(detail['networks'] as List<dynamic>?);
        numberOfSeasons = detail['number_of_seasons'] as int?;
        numberOfEpisodes = detail['number_of_episodes'] as int?;
        inProduction = detail['in_production'] as bool?;
        firstAirDate = detail['first_air_date'] as String?;
        lastAirDate = detail['last_air_date'] as String?;
      }

      final collection = detail['belongs_to_collection'] as Map<String, dynamic>?;

      return Success(
        TitleDetail(
          summary: summary,
          overview: detail['overview'] as String? ?? '',
          runtimeMinutes: type == MediaType.movie
              ? detail['runtime'] as int?
              : (detail['episode_run_time'] as List<dynamic>?)?.firstOrNull
                  as int?,
          seasons: seasons,
          cast: cast,
          tagline: detail['tagline'] as String?,
          genres: _mapGenres(detail['genres'] as List<dynamic>?),
          status: detail['status'] as String?,
          originalTitle: type == MediaType.movie
              ? detail['original_title'] as String?
              : detail['original_name'] as String?,
          originalLanguage: detail['original_language'] as String?,
          rating: (detail['vote_average'] as num?)?.toDouble(),
          voteCount: detail['vote_count'] as int?,
          popularity: (detail['popularity'] as num?)?.toDouble(),
          backdropUrl: _posterUrl(detail['backdrop_path'] as String?),
          homepage: detail['homepage'] as String?,
          imdbId: externalIds['imdb_id'] as String?,
          spokenLanguages:
              _mapSpokenLanguages(detail['spoken_languages'] as List<dynamic>?),
          countries:
              _mapCountries(detail['production_countries'] as List<dynamic>?),
          releaseDate: type == MediaType.movie
              ? detail['release_date'] as String?
              : null,
          firstAirDate: firstAirDate,
          lastAirDate: lastAirDate,
          budget: type == MediaType.movie ? detail['budget'] as int? : null,
          revenue: type == MediaType.movie ? detail['revenue'] as int? : null,
          collectionName: collection?['name'] as String?,
          createdBy: createdBy,
          networks: networks,
          numberOfSeasons: numberOfSeasons,
          numberOfEpisodes: numberOfEpisodes,
          inProduction: inProduction,
          crew: crew,
          keywords: keywords,
        ),
      );
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  TitleSummary _mapSearchResult(Map<String, dynamic> json) {
    final mediaType = MediaType.fromTmdb(json['media_type'] as String);
    final title = mediaType == MediaType.movie
        ? json['title'] as String? ?? ''
        : json['name'] as String? ?? '';
    final date = mediaType == MediaType.movie
        ? json['release_date'] as String?
        : json['first_air_date'] as String?;
    return TitleSummary(
      id: json['id'] as int,
      mediaType: mediaType,
      title: title,
      year: _parseYear(date),
      posterUrl: _posterUrl(json['poster_path'] as String?),
    );
  }

  TitleSummary _mapDetailSummary(Map<String, dynamic> json, MediaType type) {
    final title = type == MediaType.movie
        ? json['title'] as String? ?? ''
        : json['name'] as String? ?? '';
    final date = type == MediaType.movie
        ? json['release_date'] as String?
        : json['first_air_date'] as String?;
    return TitleSummary(
      id: json['id'] as int,
      mediaType: type,
      title: title,
      year: _parseYear(date),
      posterUrl: _posterUrl(json['poster_path'] as String?),
    );
  }

  List<String> _mapGenres(List<dynamic>? genres) {
    return genres
            ?.whereType<Map<String, dynamic>>()
            .map((g) => g['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> _mapKeywords(Map<String, dynamic>? keywords) {
    final list = keywords?['keywords'] as List<dynamic>?;
    return list
            ?.whereType<Map<String, dynamic>>()
            .map((k) => k['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> _mapSpokenLanguages(List<dynamic>? languages) {
    return languages
            ?.whereType<Map<String, dynamic>>()
            .map((l) => l['english_name'] as String? ?? l['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> _mapCountries(List<dynamic>? countries) {
    return countries
            ?.whereType<Map<String, dynamic>>()
            .map((c) => c['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> _mapCreatedBy(List<dynamic>? creators) {
    return creators
            ?.whereType<Map<String, dynamic>>()
            .map((c) => c['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> _mapNetworks(List<dynamic>? networks) {
    return networks
            ?.whereType<Map<String, dynamic>>()
            .map((n) => n['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];
  }

  List<Season> _mapSeasons(List<dynamic>? seasonList) {
    return seasonList
            ?.whereType<Map<String, dynamic>>()
            .where((s) => (s['season_number'] as int? ?? -1) > 0)
            .map(
              (s) => Season(
                seasonNumber: s['season_number'] as int,
                name: s['name'] as String? ?? 'Season ${s['season_number']}',
                episodeCount: s['episode_count'] as int? ?? 0,
                overview: s['overview'] as String?,
                airDate: s['air_date'] as String?,
                posterUrl: _posterUrl(s['poster_path'] as String?),
              ),
            )
            .toList() ??
        [];
  }

  List<CastMember> _mapCast(Map<String, dynamic> credits, MediaType type) {
    final castList = credits['cast'] as List<dynamic>? ?? [];
    return castList
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => CastMember(
            id: c['id'] as int? ?? c['person_id'] as int? ?? 0,
            name: c['name'] as String? ?? '',
            characterName: c['character'] as String? ??
                c['roles']?[0]?['character'] as String? ??
                '',
            profileUrl: _posterUrl(c['profile_path'] as String?),
            billingOrder: c['order'] as int? ?? 999,
          ),
        )
        .where((c) => c.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.billingOrder.compareTo(b.billingOrder));
  }

  List<CrewMember> _mapCrew(Map<String, dynamic> credits) {
    final crewList = credits['crew'] as List<dynamic>? ?? [];
    final seen = <String>{};
    final result = <CrewMember>[];

    for (final entry in crewList.whereType<Map<String, dynamic>>()) {
      final job = entry['job'] as String? ?? '';
      if (!_crewJobs.contains(job)) continue;

      final name = entry['name'] as String? ?? '';
      if (name.isEmpty) continue;

      final key = '$name|$job';
      if (seen.contains(key)) continue;
      seen.add(key);

      result.add(
        CrewMember(
          id: entry['id'] as int? ?? 0,
          name: name,
          job: job,
          department: entry['department'] as String? ?? '',
          profileUrl: _posterUrl(entry['profile_path'] as String?),
        ),
      );
    }

    return result;
  }

  int? _parseYear(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }

  String? _posterUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return '${Env.tmdbImageBaseUrl}$path';
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    if (status == 404) return const NotFoundFailure();
    if (status != null && status >= 500) return const ServerFailure();
    return ServerFailure(e.message ?? 'Request failed');
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
