import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_bloc.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_event.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_state.dart';

class MockTitleRepository extends Mock implements TitleRepository {}

class MockSceneRepository extends Mock implements SceneRepository {}

class MockBrowseHistoryService extends Mock implements BrowseHistoryService {}

void main() {
  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  late MockTitleRepository titles;
  late MockSceneRepository scenes;
  late TitleSessionHolder session;
  late MockBrowseHistoryService history;

  const movieDetail = TitleDetail(
    summary: TitleSummary(
      id: 603,
      mediaType: MediaType.movie,
      title: 'The Matrix',
    ),
    overview: 'Overview',
    cast: [],
  );

  setUp(() {
    titles = MockTitleRepository();
    scenes = MockSceneRepository();
    session = TitleSessionHolder();
    history = MockBrowseHistoryService();
    registerFallbackValue(
      const TitleSummary(id: 0, mediaType: MediaType.movie, title: 'Fallback'),
    );
    when(() => history.recordView(any())).thenAnswer((_) async {});
  });

  blocTest<TitleDetailBloc, TitleDetailState>(
    'starts movie playback setup after detail loads',
    build: () {
      when(() => titles.getDetail(603, MediaType.movie))
          .thenAnswer((_) async => const Success(movieDetail));
      when(
        () => scenes.ensureTitlePlayback(
          tmdbId: 603,
          mediaType: MediaType.movie,
          titleLabel: 'The Matrix',
          imdbId: any(named: 'imdbId'),
          episode: any(named: 'episode'),
        ),
      ).thenAnswer((_) async => const Success(7200000));
      return TitleDetailBloc(titles, scenes, session, history);
    },
    act: (bloc) => bloc.add(
      const TitleDetailRequested(id: 603, mediaType: MediaType.movie),
    ),
    expect: () => [
      const TitleDetailLoading(),
      const TitleDetailLoaded(movieDetail),
    ],
    verify: (_) async {
      await Future<void>.delayed(Duration.zero);
      verify(
        () => scenes.ensureTitlePlayback(
          tmdbId: 603,
          mediaType: MediaType.movie,
          titleLabel: 'The Matrix',
          imdbId: any(named: 'imdbId'),
          episode: null,
        ),
      ).called(1);
    },
  );

  blocTest<TitleDetailBloc, TitleDetailState>(
    'does not start playback setup for TV shows',
    build: () {
      const tvDetail = TitleDetail(
        summary: TitleSummary(
          id: 1396,
          mediaType: MediaType.tv,
          title: 'Breaking Bad',
        ),
        overview: 'Overview',
        cast: [],
      );
      when(() => titles.getDetail(1396, MediaType.tv))
          .thenAnswer((_) async => const Success(tvDetail));
      return TitleDetailBloc(titles, scenes, session, history);
    },
    act: (bloc) => bloc.add(
      const TitleDetailRequested(id: 1396, mediaType: MediaType.tv),
    ),
    expect: () => [
      const TitleDetailLoading(),
      isA<TitleDetailLoaded>(),
    ],
    verify: (_) async {
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => scenes.ensureTitlePlayback(
          tmdbId: any(named: 'tmdbId'),
          mediaType: any(named: 'mediaType'),
          titleLabel: any(named: 'titleLabel'),
          imdbId: any(named: 'imdbId'),
          episode: any(named: 'episode'),
        ),
      );
    },
  );
}
