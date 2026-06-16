import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/dialogue_line.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class MockSceneRepository extends Mock implements SceneRepository {}

class MockTitleRepository extends Mock implements TitleRepository {}

void main() {
  late MockSceneRepository repository;
  late MockTitleRepository titles;
  late TitleSessionHolder session;
  late SceneBloc bloc;

  const context = SceneContext(
    timestampMs: 2000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    activeLine: DialogueLine(startMs: 0, endMs: 5000, text: 'Neo habla con Morpheus'),
    dialogueText: 'Neo habla con Morpheus',
    askDialogueText: 'Neo habla con Morpheus',
    priorDialogueText: '',
  );

  setUpAll(() {
    registerFallbackValue(const TvEpisodeSelection(
      seasonNumber: 1,
      episodeNumber: 1,
    ));
    registerFallbackValue(
      const TitleDetail(
        summary: TitleSummary(
          id: 0,
          mediaType: MediaType.movie,
          title: 'Fallback',
        ),
        overview: '',
        cast: [],
      ),
    );
  });

  setUp(() {
    repository = MockSceneRepository();
    titles = MockTitleRepository();
    when(
      () => titles.resolveSceneCast(
        detail: any(named: 'detail'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer((_) async => const Success(<CastMember>[]));
    session = TitleSessionHolder()
      ..setTitleDetail(
        TitleDetail(
          summary: const TitleSummary(
            id: 1,
            mediaType: MediaType.movie,
            title: 'Matrix',
          ),
          overview: '',
          cast: const [],
        ),
      )
      ..setDurationMs(5000);
    bloc = SceneBloc(repository, titles, session);
  });

  tearDown(() => bloc.close());

  blocTest<SceneBloc, SceneState>(
    'emits loaded when timestamp changes',
    build: () {
      when(
        () => repository.prepareScene(
          tmdbId: 1,
          mediaType: MediaType.movie,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
        ),
      ).thenAnswer((_) async => const Success(5000));
      when(
        () => repository.getContext(
          tmdbId: 1,
          mediaType: MediaType.movie,
          timestampMs: 2000,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
        ),
      ).thenAnswer((_) async => const Success(context));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const SceneStarted(
        tmdbId: 1,
        mediaType: MediaType.movie,
        initialTimestampMs: 2000,
      ),
    ),
    expect: () => [
      const SceneLoading(),
      isA<SceneLoaded>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'prepares scene then awaits a timestamp instead of loading 0',
    build: () {
      when(
        () => repository.prepareScene(
          tmdbId: 1,
          mediaType: MediaType.movie,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
        ),
      ).thenAnswer((_) async => const Success(5000));
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 1, mediaType: MediaType.movie),
    ),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'emits failure when prepare fails',
    build: () {
      when(
        () => repository.prepareScene(
          tmdbId: 1,
          mediaType: MediaType.movie,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
        ),
      ).thenAnswer(
        (_) async => const Error(NotFoundFailure('Scene dialogue not available')),
      );
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 1, mediaType: MediaType.movie),
    ),
    expect: () => [
      const SceneLoading(),
      isA<SceneFailure>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'awaits episode selection for TV without season and episode',
    build: () {
      session
        ..setTitleDetail(
          TitleDetail(
            summary: const TitleSummary(
              id: 10,
              mediaType: MediaType.tv,
              title: 'Breaking Bad',
            ),
            overview: '',
            cast: const [],
            seasons: const [
              Season(
                seasonNumber: 1,
                name: 'Season 1',
                episodeCount: 7,
              ),
            ],
          ),
        )
        ..durationMs = null;
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 10, mediaType: MediaType.tv),
    ),
    expect: () => [const SceneAwaitingEpisode()],
  );

  blocTest<SceneBloc, SceneState>(
    'prepares scene for selected TV episode',
    build: () {
      session
        ..setTitleDetail(
          TitleDetail(
            summary: const TitleSummary(
              id: 10,
              mediaType: MediaType.tv,
              title: 'Breaking Bad',
            ),
            overview: '',
            cast: const [],
            seasons: const [
              Season(
                seasonNumber: 1,
                name: 'Season 1',
                episodeCount: 7,
              ),
            ],
          ),
        )
        ..durationMs = null;
      when(
        () => repository.prepareScene(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
        ),
      ).thenAnswer((_) async => const Success(3600000));
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(
        tmdbId: 10,
        mediaType: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: 3,
      ),
    ),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'stores episode scene cast when preparing a TV episode',
    build: () {
      const episodeCast = [
        CastMember(
          id: 1,
          name: 'Bryan Cranston',
          characterName: 'Walter White',
          billingOrder: 0,
        ),
      ];
      session
        ..setTitleDetail(
          TitleDetail(
            summary: const TitleSummary(
              id: 10,
              mediaType: MediaType.tv,
              title: 'Breaking Bad',
            ),
            overview: '',
            cast: const [
              CastMember(
                id: 99,
                name: 'Series Regular',
                characterName: 'Series Character',
                billingOrder: 0,
              ),
            ],
            seasons: const [
              Season(
                seasonNumber: 1,
                name: 'Season 1',
                episodeCount: 7,
              ),
            ],
          ),
        )
        ..durationMs = null;
      when(
        () => titles.resolveSceneCast(
          detail: any(named: 'detail'),
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
        ),
      ).thenAnswer((_) async => const Success(episodeCast));
      when(
        () => repository.prepareScene(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
        ),
      ).thenAnswer((_) async => const Success(3600000));
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(
        tmdbId: 10,
        mediaType: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: 3,
      ),
    ),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
    verify: (_) {
      expect(session.sceneCast, hasLength(1));
      expect(session.sceneCast.first.characterName, 'Walter White');
    },
  );

  blocTest<SceneBloc, SceneState>(
    'uses route media type when session title id does not match',
    build: () {
      session
        ..setTitleDetail(
          TitleDetail(
            summary: const TitleSummary(
              id: 10,
              mediaType: MediaType.tv,
              title: 'Breaking Bad',
            ),
            overview: '',
            cast: const [],
            seasons: const [
              Season(
                seasonNumber: 1,
                name: 'Season 1',
                episodeCount: 7,
              ),
            ],
          ),
        )
        ..setSelectedEpisode(
          const TvEpisodeSelection(seasonNumber: 1, episodeNumber: 1),
        )
        ..durationMs = null;
      when(
        () => repository.prepareScene(
          tmdbId: 27205,
          mediaType: MediaType.movie,
          episode: null,
          titleLabel: 'Breaking Bad',
        ),
      ).thenAnswer((_) async => const Success(7200000));
      return SceneBloc(repository, titles, session);
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 27205, mediaType: MediaType.movie),
    ),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
  );
}
