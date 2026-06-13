import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/services/tmdb_service.dart';
import 'package:storypilot/domain/models/crew_member.dart';
import 'package:storypilot/domain/models/episode.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late TmdbService service;

  setUp(() {
    dio = MockDio();
    service = TmdbService(dio, apiKey: 'test');
  });

  group('TitleDetail serialization', () {
    test('fromJson tolerates legacy cache without new fields', () {
      final detail = TitleDetail.fromJson({
        'summary': {
          'id': 1,
          'mediaType': 'movie',
          'title': 'Matrix',
        },
        'overview': 'A hacker discovers reality.',
        'runtimeMinutes': 136,
        'cast': [],
      });

      expect(detail.summary.title, 'Matrix');
      expect(detail.genres, isEmpty);
      expect(detail.crew, isEmpty);
      expect(detail.keywords, isEmpty);
    });

    test('toJson/fromJson roundtrip preserves enriched fields', () {
      const original = TitleDetail(
        summary: TitleSummary(
          id: 550,
          mediaType: MediaType.movie,
          title: 'Fight Club',
          year: 1999,
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
        ),
        overview: 'An insomniac office worker...',
        runtimeMinutes: 139,
        cast: [],
        tagline: 'Mischief. Mayhem. Soap.',
        genres: ['Drama', 'Thriller'],
        status: 'Released',
        rating: 8.4,
        voteCount: 28000,
        backdropUrl: 'https://image.tmdb.org/t/p/w500/backdrop.jpg',
        imdbId: 'tt0137523',
        spokenLanguages: ['English'],
        countries: ['United States of America'],
        releaseDate: '1999-10-15',
        budget: 63000000,
        revenue: 100900000,
        crew: [
          CrewMember(
            id: 7467,
            name: 'David Fincher',
            job: 'Director',
            department: 'Directing',
          ),
        ],
        keywords: ['dual identity', 'support group'],
      );

      final restored = TitleDetail.fromJson(original.toJson());

      expect(restored.tagline, original.tagline);
      expect(restored.genres, original.genres);
      expect(restored.crew.first.name, 'David Fincher');
      expect(restored.keywords, original.keywords);
      expect(restored.budget, 63000000);
    });
  });

  group('fetchDetail mapping', () {
    final movieFixture = {
      'id': 550,
      'title': 'Fight Club',
      'original_title': 'Fight Club',
      'overview': 'An insomniac office worker...',
      'tagline': 'Mischief. Mayhem. Soap.',
      'release_date': '1999-10-15',
      'runtime': 139,
      'status': 'Released',
      'vote_average': 8.438,
      'vote_count': 28000,
      'popularity': 20.5,
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'original_language': 'en',
      'budget': 63000000,
      'revenue': 100900000,
      'homepage': 'http://www.foxmovies.com/movies/fight-club',
      'genres': [
        {'id': 18, 'name': 'Drama'},
        {'id': 53, 'name': 'Thriller'},
      ],
      'spoken_languages': [
        {'english_name': 'English', 'iso_639_1': 'en', 'name': 'English'},
      ],
      'production_countries': [
        {'iso_3166_1': 'US', 'name': 'United States of America'},
      ],
      'belongs_to_collection': null,
      'credits': {
        'cast': [
          {
            'id': 819,
            'name': 'Edward Norton',
            'character': 'The Narrator',
            'order': 0,
            'profile_path': '/norton.jpg',
          },
        ],
        'crew': [
          {
            'id': 7467,
            'name': 'David Fincher',
            'job': 'Director',
            'department': 'Directing',
            'profile_path': '/fincher.jpg',
          },
          {
            'id': 9999,
            'name': 'Some Editor',
            'job': 'Editor',
            'department': 'Editing',
          },
        ],
      },
      'keywords': {
        'keywords': [
          {'id': 1, 'name': 'dual identity'},
          {'id': 2, 'name': 'support group'},
        ],
      },
      'external_ids': {'imdb_id': 'tt0137523'},
    };

    final tvFixture = {
      'id': 1396,
      'name': 'Breaking Bad',
      'original_name': 'Breaking Bad',
      'overview': 'A chemistry teacher turned meth maker.',
      'tagline': 'Change the equation.',
      'first_air_date': '2008-01-20',
      'last_air_date': '2013-09-29',
      'status': 'Ended',
      'vote_average': 8.9,
      'vote_count': 15000,
      'popularity': 100.0,
      'poster_path': '/bb.jpg',
      'backdrop_path': '/bb_backdrop.jpg',
      'original_language': 'en',
      'in_production': false,
      'number_of_seasons': 5,
      'number_of_episodes': 62,
      'episode_run_time': [45, 50],
      'genres': [
        {'id': 18, 'name': 'Drama'},
      ],
      'created_by': [
        {'id': 1, 'name': 'Vince Gilligan'},
      ],
      'networks': [
        {'id': 174, 'name': 'AMC'},
      ],
      'spoken_languages': [
        {'english_name': 'English', 'iso_639_1': 'en', 'name': 'English'},
      ],
      'production_countries': [
        {'iso_3166_1': 'US', 'name': 'United States of America'},
      ],
      'seasons': [
        {
          'season_number': 0,
          'name': 'Specials',
          'episode_count': 10,
          'overview': '',
          'air_date': null,
          'poster_path': null,
        },
        {
          'season_number': 1,
          'name': 'Season 1',
          'episode_count': 7,
          'overview': 'Season one overview.',
          'air_date': '2008-01-20',
          'poster_path': '/s1.jpg',
        },
      ],
      'aggregate_credits': {
        'cast': [
          {
            'id': 17419,
            'name': 'Bryan Cranston',
            'roles': [
              {'character': 'Walter White'},
            ],
            'order': 0,
            'profile_path': '/cranston.jpg',
          },
        ],
        'crew': [
          {
            'id': 1,
            'name': 'Vince Gilligan',
            'job': 'Writer',
            'department': 'Writing',
          },
        ],
      },
      'keywords': {
        'keywords': [
          {'id': 10, 'name': 'drugs'},
        ],
      },
      'external_ids': {'imdb_id': 'tt0903747'},
    };

    test('maps movie detail with genres crew and keywords', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: movieFixture,
          requestOptions: RequestOptions(path: '/movie/550'),
        ),
      );

      final result = await service.fetchDetail(550, MediaType.movie);

      expect(result, isA<Success<TitleDetail>>());
      final detail = (result as Success<TitleDetail>).data;
      expect(detail.summary.title, 'Fight Club');
      expect(detail.genres, ['Drama', 'Thriller']);
      expect(detail.tagline, 'Mischief. Mayhem. Soap.');
      expect(detail.rating, closeTo(8.438, 0.001));
      expect(detail.imdbId, 'tt0137523');
      expect(detail.crew, hasLength(1));
      expect(detail.crew.first.job, 'Director');
      expect(detail.keywords, ['dual identity', 'support group']);
      expect(detail.cast.first.characterName, 'The Narrator');
      expect(detail.budget, 63000000);
      expect(detail.backdropUrl, contains('backdrop.jpg'));
    });

    test('maps TV detail with seasons and aggregate credits', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tvFixture,
          requestOptions: RequestOptions(path: '/tv/1396'),
        ),
      );

      final result = await service.fetchDetail(1396, MediaType.tv);

      expect(result, isA<Success<TitleDetail>>());
      final detail = (result as Success<TitleDetail>).data;
      expect(detail.summary.title, 'Breaking Bad');
      expect(detail.createdBy, ['Vince Gilligan']);
      expect(detail.networks, ['AMC']);
      expect(detail.numberOfSeasons, 5);
      expect(detail.seasons, hasLength(1));
      expect(detail.seasons!.first.seasonNumber, 1);
      expect(detail.seasons!.first.overview, 'Season one overview.');
      expect(detail.cast.first.characterName, 'Walter White');
      expect(detail.crew.first.job, 'Writer');
      expect(detail.keywords, ['drugs']);
      expect(detail.runtimeMinutes, 45);
    });
  });

  group('fetchPopularMovies', () {
    test('maps movie list from popular endpoint', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 550,
                'title': 'Fight Club',
                'release_date': '1999-10-15',
                'poster_path': '/poster.jpg',
              },
            ],
          },
          requestOptions: RequestOptions(path: '/movie/popular'),
        ),
      );

      final result = await service.fetchPopularMovies();

      expect(result, isA<Success<List<TitleSummary>>>());
      final movies = (result as Success<List<TitleSummary>>).data;
      expect(movies, hasLength(1));
      expect(movies.first.title, 'Fight Club');
      expect(movies.first.mediaType, MediaType.movie);
      expect(movies.first.year, 1999);
      expect(movies.first.posterUrl, contains('poster.jpg'));
    });
  });

  group('fetchPopularSeries', () {
    test('maps TV list from popular endpoint', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 1396,
                'name': 'Breaking Bad',
                'first_air_date': '2008-01-20',
                'poster_path': '/bb.jpg',
              },
            ],
          },
          requestOptions: RequestOptions(path: '/tv/popular'),
        ),
      );

      final result = await service.fetchPopularSeries();

      expect(result, isA<Success<List<TitleSummary>>>());
      final series = (result as Success<List<TitleSummary>>).data;
      expect(series, hasLength(1));
      expect(series.first.title, 'Breaking Bad');
      expect(series.first.mediaType, MediaType.tv);
      expect(series.first.year, 2008);
    });
  });

  group('fetchSeasonEpisodes', () {
    test('maps episode list from season detail', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'episodes': [
              {
                'episode_number': 1,
                'name': 'Pilot',
                'overview': 'First episode.',
                'air_date': '2008-01-20',
                'still_path': '/still.jpg',
                'runtime': 58,
              },
              {
                'episode_number': 2,
                'name': "Cat's in the Bag...",
                'overview': '',
                'air_date': '2008-01-27',
                'still_path': null,
                'runtime': 48,
              },
            ],
          },
          requestOptions: RequestOptions(path: '/tv/1396/season/1'),
        ),
      );

      final result = await service.fetchSeasonEpisodes(1396, 1);

      expect(result, isA<Success<List<Episode>>>());
      final episodes = (result as Success<List<Episode>>).data;
      expect(episodes, hasLength(2));
      expect(episodes.first.episodeNumber, 1);
      expect(episodes.first.name, 'Pilot');
      expect(episodes.first.overview, 'First episode.');
      expect(episodes.first.airDate, '2008-01-20');
      expect(episodes.first.stillUrl, contains('still.jpg'));
      expect(episodes.first.runtimeMinutes, 58);
      expect(episodes[1].name, "Cat's in the Bag...");
      expect(episodes[1].stillUrl, isNull);
    });
  });
}
