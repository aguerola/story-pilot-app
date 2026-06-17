import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:storypilot/config/env.dart';
import 'package:storypilot/data/services/tmdb_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/crew_member.dart';
import 'package:storypilot/domain/models/person_detail.dart';
import 'package:storypilot/domain/models/episode.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';

class TmdbService {
  TmdbService(this._client);

  final TmdbFunctionsClient _client;

  static const _crewJobs = {
    'Director',
    'Writer',
    'Screenplay',
    'Novel',
    'Original Music Composer',
  };

  Future<Result<List<TitleSummary>>> fetchPopularMovies() async {
    return _fetchPopularList(MediaType.movie);
  }

  Future<Result<List<TitleSummary>>> fetchPopularSeries() async {
    return _fetchPopularList(MediaType.tv);
  }

  Future<Result<List<TitleSummary>>> _fetchPopularList(
    MediaType mediaType,
  ) async {
    try {
      final data = await _client.call({
        'op': mediaType == MediaType.movie ? 'popularMovies' : 'popularSeries',
      });
      final results = data['results'] as List<dynamic>? ?? [];
      final summaries = results
          .whereType<Map<String, dynamic>>()
          .map((json) => _mapListItem(json, mediaType))
          .toList();
      return Success(summaries);
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<TitleSummary>>> search(String query) async {
    try {
      final data = await _client.call({
        'op': 'search',
        'query': query,
      });
      final results = data['results'] as List<dynamic>? ?? [];
      final summaries = results
          .whereType<Map<String, dynamic>>()
          .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
          .map(_mapSearchResult)
          .toList();
      return Success(summaries);
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<TitleDetail>> fetchDetail(int id, MediaType type) async {
    try {
      final detail = await _client.call({
        'op': 'detail',
        'id': id,
        'mediaType': type == MediaType.movie ? 'movie' : 'tv',
      });
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
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  TitleSummary _mapSearchResult(Map<String, dynamic> json) {
    final mediaType = MediaType.fromTmdb(json['media_type'] as String);
    return _mapListItem(json, mediaType);
  }

  TitleSummary _mapListItem(Map<String, dynamic> json, MediaType mediaType) {
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

  Future<Result<List<Episode>>> fetchSeasonEpisodes(
    int tvId,
    int seasonNumber,
  ) async {
    try {
      final data = await _client.call({
        'op': 'seasonEpisodes',
        'tvId': tvId,
        'seasonNumber': seasonNumber,
      });
      final episodes = _mapEpisodes(data['episodes'] as List<dynamic>?);
      return Success(episodes);
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<PersonDetail>> fetchPersonDetail(int personId) async {
    try {
      final data = await _client.call({
        'op': 'personDetail',
        'id': personId,
      });
      return Success(_mapPersonDetail(data));
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<CastMember>>> fetchEpisodeCredits(
    int tvId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    try {
      final data = await _client.call({
        'op': 'episodeCredits',
        'tvId': tvId,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
      });
      return Success(_mapEpisodeCredits(data));
    } on FirebaseFunctionsException catch (e) {
      return Error(_mapFunctionsError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  List<Episode> _mapEpisodes(List<dynamic>? episodeList) {
    return episodeList
            ?.whereType<Map<String, dynamic>>()
            .map(
              (e) => Episode(
                episodeNumber: e['episode_number'] as int,
                name: e['name'] as String? ??
                    'Capítulo ${e['episode_number']}',
                overview: e['overview'] as String?,
                airDate: e['air_date'] as String?,
                stillUrl: _posterUrl(e['still_path'] as String?),
                runtimeMinutes: e['runtime'] as int?,
              ),
            )
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

  List<CastMember> _mapEpisodeCredits(Map<String, dynamic> credits) {
    final entries = <Map<String, dynamic>>[
      ...(credits['cast'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>(),
      ...(credits['guest_stars'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>(),
    ];
    final seen = <int>{};
    final result = <CastMember>[];

    for (final entry in entries) {
      final id = entry['id'] as int? ?? 0;
      if (id == 0 || !seen.add(id)) continue;

      final name = entry['name'] as String? ?? '';
      final characterName = (entry['character'] as String? ?? '').trim();
      if (name.isEmpty || characterName.isEmpty) continue;

      result.add(
        CastMember(
          id: id,
          name: name,
          characterName: characterName,
          profileUrl: _posterUrl(entry['profile_path'] as String?),
          billingOrder: entry['order'] as int? ?? 999,
        ),
      );
    }

    result.sort((a, b) => a.billingOrder.compareTo(b.billingOrder));
    return result;
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

  PersonDetail _mapPersonDetail(Map<String, dynamic> json) {
    final combinedCredits = json['combined_credits'];
    return PersonDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      biography: _trimOrNull(json['biography'] as String?),
      birthday: _trimOrNull(json['birthday'] as String?),
      placeOfBirth: _trimOrNull(json['place_of_birth'] as String?),
      profileUrl: _posterUrl(json['profile_path'] as String?),
      knownFor: combinedCredits is Map<String, dynamic>
          ? _mapKnownFor(combinedCredits)
          : const [],
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  List<PersonKnownForCredit> _mapKnownFor(Map<String, dynamic> combinedCredits) {
    final cast = combinedCredits['cast'] as List<dynamic>? ?? [];
    final entries = cast.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) {
        final aPop = (a['popularity'] as num?)?.toDouble() ?? 0;
        final bPop = (b['popularity'] as num?)?.toDouble() ?? 0;
        return bPop.compareTo(aPop);
      });

    return entries.take(5).map((entry) {
      final mediaType = entry['media_type'] as String? ?? 'movie';
      final title = mediaType == 'movie'
          ? entry['title'] as String? ?? ''
          : entry['name'] as String? ?? '';
      final date = mediaType == 'movie'
          ? entry['release_date'] as String?
          : entry['first_air_date'] as String?;

      return PersonKnownForCredit(
        title: title,
        characterName: _trimOrNull(entry['character'] as String?),
        year: _parseYear(date),
        posterUrl: _posterUrl(entry['poster_path'] as String?),
        mediaType: mediaType,
      );
    }).where((credit) => credit.title.isNotEmpty).toList();
  }

  Failure _mapFunctionsError(FirebaseFunctionsException e) {
    if (e.code == 'unavailable') {
      final message = e.message ?? '';
      if (message.contains('404') || message.contains('(404)')) {
        return const NotFoundFailure();
      }
      if (message.contains('timeout') || message.contains('network')) {
        return const NetworkFailure();
      }
      return ServerFailure(message.isEmpty ? 'TMDB request failed' : message);
    }
    if (e.code == 'deadline-exceeded') {
      return const NetworkFailure();
    }
    return ServerFailure(e.message ?? 'TMDB request failed');
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
