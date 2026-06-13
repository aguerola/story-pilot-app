import 'package:dio/dio.dart';
import 'package:storypilot/config/env.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';

class TmdbService {
  TmdbService(this._dio);

  final Dio _dio;

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
      final detailResponse = await _dio.get<Map<String, dynamic>>(
        Env.wrapUrl('${Env.tmdbBaseUrl}/$path/$id'),
        queryParameters: {'api_key': Env.tmdbApiKey},
      );
      final creditsPath =
          type == MediaType.movie ? 'movie/$id/credits' : 'tv/$id/aggregate_credits';
      final creditsResponse = await _dio.get<Map<String, dynamic>>(
        Env.wrapUrl('${Env.tmdbBaseUrl}/$creditsPath'),
        queryParameters: {'api_key': Env.tmdbApiKey},
      );
      final detail = detailResponse.data!;
      final credits = creditsResponse.data!;
      final summary = _mapDetailSummary(detail, type);
      final cast = _mapCast(credits, type);
      List<Season>? seasons;
      if (type == MediaType.tv) {
        final seasonList = detail['seasons'] as List<dynamic>? ?? [];
        seasons = seasonList
            .whereType<Map<String, dynamic>>()
            .where((s) => (s['season_number'] as int? ?? -1) > 0)
            .map(
              (s) => Season(
                seasonNumber: s['season_number'] as int,
                name: s['name'] as String? ?? 'Season ${s['season_number']}',
                episodeCount: s['episode_count'] as int? ?? 0,
              ),
            )
            .toList();
      }
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
