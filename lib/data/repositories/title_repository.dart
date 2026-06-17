import 'package:storypilot/config/brief_cast.dart';
import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/tmdb_service.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/episode.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/person_detail.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';

class TitleRepository {
  TitleRepository(this._tmdb, this._cache);

  final TmdbService _tmdb;
  final LocalCacheService _cache;

  Future<Result<List<TitleSummary>>> search(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const Success([]));
    }
    return _tmdb.search(query.trim());
  }

  Future<Result<TitleDetail>> getDetail(int id, MediaType type) async {
    final cached = await _cache.getTitle(id, type);
    if (cached != null && !cached.isExpired) {
      return Success(cached.data);
    }

    final remote = await _tmdb.fetchDetail(id, type);
    if (remote is Success<TitleDetail>) {
      await _cache.saveTitle(id, type, remote.data);
    }
    return remote;
  }

  Future<Result<List<Episode>>> getSeasonEpisodes(
    int tvId,
    int seasonNumber,
  ) {
    return _tmdb.fetchSeasonEpisodes(tvId, seasonNumber);
  }

  Future<Result<List<CastMember>>> resolveSceneCast({
    required TitleDetail detail,
    TvEpisodeSelection? episode,
  }) async {
    final seriesCast = detail.cast;

    if (detail.summary.mediaType == MediaType.movie || episode == null) {
      return Success(seriesCast.take(maxBriefCast).toList());
    }

    final episodeResult = await _tmdb.fetchEpisodeCredits(
      detail.summary.id,
      episode.seasonNumber,
      episode.episodeNumber,
    );

    final resolvedCast = switch (episodeResult) {
      Success(:final data) when data.isNotEmpty => data,
      _ => seriesCast,
    };

    return Success(resolvedCast.take(maxBriefCast).toList());
  }

  Future<Result<List<TitleSummary>>> getPopularMovies() {
    return _tmdb.fetchPopularMovies();
  }

  Future<Result<List<TitleSummary>>> getPopularSeries() {
    return _tmdb.fetchPopularSeries();
  }

  Future<Result<PersonDetail>> getPersonDetail(int personId) {
    return _tmdb.fetchPersonDetail(personId);
  }
}
