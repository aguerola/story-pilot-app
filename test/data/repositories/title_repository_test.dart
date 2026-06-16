import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/config/brief_cast.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/tmdb_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';

class MockTmdbService extends Mock implements TmdbService {}

class MockLocalCacheService extends Mock implements LocalCacheService {}

void main() {
  late MockTmdbService tmdb;
  late TitleRepository repository;

  const episode = TvEpisodeSelection(seasonNumber: 1, episodeNumber: 1);

  TitleDetail tvDetail(List<CastMember> cast) => TitleDetail(
        summary: const TitleSummary(
          id: 1396,
          mediaType: MediaType.tv,
          title: 'Game of Thrones',
        ),
        overview: '',
        cast: cast,
      );

  List<CastMember> seriesCast(int count) => List.generate(
        count,
        (index) => CastMember(
          id: index,
          name: 'Actor $index',
          characterName: 'Character $index',
          billingOrder: index,
        ),
      );

  setUp(() {
    tmdb = MockTmdbService();
    repository = TitleRepository(tmdb, MockLocalCacheService());
  });

  test('movie uses series cast capped at maxBriefCast', () async {
    final detail = TitleDetail(
      summary: const TitleSummary(
        id: 550,
        mediaType: MediaType.movie,
        title: 'Fight Club',
      ),
      overview: '',
      cast: seriesCast(50),
    );

    final result = await repository.resolveSceneCast(detail: detail);

    expect(result, isA<Success<List<CastMember>>>());
    expect((result as Success<List<CastMember>>).data, hasLength(maxBriefCast));
    expect((result).data.first.characterName, 'Character 0');
  });

  test('tv episode uses episode credits when available', () async {
    const episodeCast = [
      CastMember(
        id: 1,
        name: 'Peter Dinklage',
        characterName: 'Tyrion Lannister',
        billingOrder: 0,
      ),
    ];

    when(
      () => tmdb.fetchEpisodeCredits(1396, 1, 1),
    ).thenAnswer((_) async => const Success(episodeCast));

    final result = await repository.resolveSceneCast(
      detail: tvDetail(seriesCast(100)),
      episode: episode,
    );

    expect((result as Success<List<CastMember>>).data, episodeCast);
    verify(() => tmdb.fetchEpisodeCredits(1396, 1, 1)).called(1);
  });

  test('tv episode falls back to series cast when episode credits are empty',
      () async {
    when(
      () => tmdb.fetchEpisodeCredits(1396, 1, 1),
    ).thenAnswer((_) async => const Success([]));

    final result = await repository.resolveSceneCast(
      detail: tvDetail(seriesCast(50)),
      episode: episode,
    );

    expect((result as Success<List<CastMember>>).data, hasLength(maxBriefCast));
    expect((result).data.first.characterName, 'Character 0');
  });

  test('tv episode falls back to series cast when episode credits fail',
      () async {
    when(
      () => tmdb.fetchEpisodeCredits(1396, 1, 1),
    ).thenAnswer((_) async => const Error(NetworkFailure()));

    final result = await repository.resolveSceneCast(
      detail: tvDetail(seriesCast(10)),
      episode: episode,
    );

    expect((result as Success<List<CastMember>>).data, hasLength(10));
  });
}
