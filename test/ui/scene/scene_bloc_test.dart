import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/dialogue_line.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/scene_breakdown.dart';
import 'package:storypilot/domain/models/title_preprocessing.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class MockSceneRepository extends Mock implements SceneRepository {}

class MockTitleRepository extends Mock implements TitleRepository {}

const _testBreakdown = TitleBreakdown(
  durationMs: 5000,
  titleLabel: 'Matrix',
  scenes: [
    SceneSegment(
      startMs: 0,
      endMs: 5000,
      summary: 'Opening',
      detailedSummary: 'Neo meets Morpheus.',
      characters: ['Neo'],
    ),
  ],
  analysisVersion: 3,
  generatedAt: 1,
);

const _readyPreprocessing = TitlePreprocessingResult.ready(
  breakdown: _testBreakdown,
);

const _tvBreakdown = TitleBreakdown(
  durationMs: 3600000,
  titleLabel: 'Breaking Bad',
  scenes: [
    SceneSegment(
      startMs: 0,
      endMs: 3600000,
      summary: 'Episode',
      detailedSummary: 'Walter cooks.',
      characters: ['Walter White'],
    ),
  ],
  analysisVersion: 3,
  generatedAt: 1,
);

const _tvReadyPreprocessing = TitlePreprocessingResult.ready(
  breakdown: _tvBreakdown,
);

const _movieBreakdown = TitleBreakdown(
  durationMs: 7200000,
  titleLabel: 'Breaking Bad',
  scenes: [
    SceneSegment(
      startMs: 0,
      endMs: 7200000,
      summary: 'Movie',
      detailedSummary: 'Inception begins.',
      characters: ['Cobb'],
    ),
  ],
  analysisVersion: 3,
  generatedAt: 1,
);

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
    registerFallbackValue(MediaType.movie);
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
    bloc = SceneBloc(
      repository,
      titles,
      session,
      preprocessingPollInterval: const Duration(milliseconds: 1),
      preprocessingTimeout: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => bloc.close());

  blocTest<SceneBloc, SceneState>(
    'shows preprocessed scene instantly on scrub without calling getContext',
    build: () {
      session.setTitleBreakdown(_testBreakdown);
      return bloc;
    },
    act: (bloc) => bloc.add(const TimestampScrubbed(2000)),
    expect: () => [
      isA<SceneLoaded>()
          .having((state) => state.isPreview, 'isPreview', true)
          .having((state) => state.isBriefLoading, 'isBriefLoading', false)
          .having(
            (state) => state.displaySummary,
            'displaySummary',
            'Neo meets Morpheus.',
          ),
    ],
    verify: (_) {
      verifyNever(
        () => repository.getContext(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          timestampMs: any(named: 'timestampMs'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      );
    },
  );

  blocTest<SceneBloc, SceneState>(
    'shows preprocessed scene instantly then brief when timestamp changes',
    build: () {
      session.setTitleBreakdown(_testBreakdown);
      when(
        () => repository.getContext(
          tmdbId: 1,
          mediaType: MediaType.movie,
          timestampMs: 2000,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneContextWithBrief(
            context: context,
            brief: SceneBrief(
              summary: 'Brief from Gemini.',
              presentCharacterNames: ['Neo'],
              questions: ['¿Qué pasa?'],
            ),
          ),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const TimestampChanged(2000)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      isA<SceneLoaded>()
          .having((state) => state.isPreview, 'isPreview', false)
          .having((state) => state.isBriefLoading, 'isBriefLoading', true)
          .having(
            (state) => state.preprocessedSummary,
            'preprocessedSummary',
            'Neo meets Morpheus.',
          ),
      isA<SceneLoaded>()
          .having((state) => state.isBriefLoading, 'isBriefLoading', false)
          .having(
            (state) => state.summary,
            'summary',
            'Brief from Gemini.',
          ),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'falls back to loading when breakdown is unavailable',
    build: () {
      when(
        () => repository.getContext(
          tmdbId: 1,
          mediaType: MediaType.movie,
          timestampMs: 2000,
          episode: any(named: 'episode'),
          titleLabel: 'Matrix',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneContextWithBrief(context: context),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const TimestampChanged(2000)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      const SceneLoading(),
      isA<SceneLoaded>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'waits for preprocessing then awaits a timestamp for movies',
    build: () {
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(_readyPreprocessing));
      return SceneBloc(
      repository,
      titles,
      session,
      preprocessingPollInterval: const Duration(milliseconds: 1),
      preprocessingTimeout: const Duration(milliseconds: 20),
      );
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 1, mediaType: MediaType.movie),
    ),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
    verify: (_) {
      verifyNever(
        () => repository.ensureTitlePlayback(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      );
      verify(
        () => repository.getTitlePreprocessing(
          tmdbId: 1,
          mediaType: MediaType.movie,
          episode: null,
          titleLabel: 'Matrix',
          imdbId: any(named: 'imdbId'),
        ),
      ).called(1);
    },
  );

  blocTest<SceneBloc, SceneState>(
    'polls preprocessing until ready',
    build: () {
      var calls = 0;
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return const Success(TitlePreprocessingResult.pending());
        }
        return const Success(_readyPreprocessing);
      });
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 10),
        preprocessingTimeout: const Duration(seconds: 1),
      );
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 1, mediaType: MediaType.movie),
    ),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
    ],
    verify: (_) {
      verify(
        () => repository.getTitlePreprocessing(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      ).called(2);
    },
  );

  blocTest<SceneBloc, SceneState>(
    'emits preprocessing failure on timeout',
    build: () {
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(TitlePreprocessingResult.pending()));
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 10),
        preprocessingTimeout: const Duration(milliseconds: 25),
      );
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 1, mediaType: MediaType.movie),
    ),
    wait: const Duration(milliseconds: 80),
    expect: () => [
      const SceneLoading(),
      isA<ScenePreprocessingFailure>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'retries preprocessing after failure',
    build: () {
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          episode: any(named: 'episode'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(_readyPreprocessing));
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
    },
    act: (bloc) async {
      bloc.add(const SceneStarted(tmdbId: 1, mediaType: MediaType.movie));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const PreprocessingRetry());
    },
    wait: const Duration(milliseconds: 80),
    expect: () => [
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
      const SceneLoading(),
      const SceneAwaitingTimestamp(),
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
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
    },
    act: (bloc) => bloc.add(
      const SceneStarted(tmdbId: 10, mediaType: MediaType.tv),
    ),
    expect: () => [const SceneAwaitingEpisode()],
  );

  blocTest<SceneBloc, SceneState>(
    'ensures playback then waits for preprocessing for TV episode',
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
        () => repository.ensureTitlePlayback(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(3600000));
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(_tvReadyPreprocessing));
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
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
    'emits failure when TV ensureTitlePlayback fails',
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
          ),
        )
        ..durationMs = null;
      when(
        () => repository.ensureTitlePlayback(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer(
        (_) async => const Error(NotFoundFailure('Scene dialogue not available')),
      );
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
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
      isA<SceneFailure>(),
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
        () => repository.ensureTitlePlayback(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(3600000));
      when(
        () => repository.getTitlePreprocessing(
          tmdbId: 10,
          mediaType: MediaType.tv,
          episode: const TvEpisodeSelection(
            seasonNumber: 1,
            episodeNumber: 3,
          ),
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer((_) async => const Success(_tvReadyPreprocessing));
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
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
        () => repository.getTitlePreprocessing(
          tmdbId: 27205,
          mediaType: MediaType.movie,
          episode: null,
          titleLabel: 'Breaking Bad',
          imdbId: any(named: 'imdbId'),
        ),
      ).thenAnswer(
        (_) async => Success(
          TitlePreprocessingResult.ready(breakdown: _movieBreakdown),
        ),
      );
      return SceneBloc(
        repository,
        titles,
        session,
        preprocessingPollInterval: const Duration(milliseconds: 1),
        preprocessingTimeout: const Duration(milliseconds: 20),
      );
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
