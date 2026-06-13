import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class MockSceneRepository extends Mock implements SceneRepository {}

class MockSubtitleRepository extends Mock implements SubtitleRepository {}

void main() {
  late MockSceneRepository repository;
  late MockSubtitleRepository subtitleRepository;
  late TitleSessionHolder session;
  late SceneBloc bloc;

  final document = SubtitleDocument(
    titleId: 1,
    language: 'es',
    fileId: 'abc',
    lines: const [
      SubtitleLine(startMs: 0, endMs: 5000, text: 'Neo habla con Morpheus'),
    ],
  );

  final context = SceneContext(
    timestampMs: 2000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    activeLine: document.lines.first,
    dialogueText: 'Neo habla con Morpheus',
    askDialogueText: 'Neo habla con Morpheus',
    priorDialogueText: '',
    characters: [
      SceneCharacter(
        castMember: const CastMember(
          id: 1,
          name: 'Keanu Reeves',
          characterName: 'Neo',
          billingOrder: 0,
        ),
        confidence: MatchConfidence.high,
        matchedBy: 'test',
      ),
    ],
  );

  setUp(() {
    repository = MockSceneRepository();
    subtitleRepository = MockSubtitleRepository();
    when(() => subtitleRepository.getCachedForTitle(any()))
        .thenAnswer((_) async => null);
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
      ..setSubtitleDocument(document);
    bloc = SceneBloc(repository, subtitleRepository, session);
  });

  tearDown(() => bloc.close());

  blocTest<SceneBloc, SceneState>(
    'emits loaded when timestamp changes',
    build: () {
      when(
        () => repository.getContext(
          subtitles: document,
          cast: const [],
          timestampMs: 2000,
          titleLabel: 'Matrix',
        ),
      ).thenAnswer((_) async => Success(context));
      return bloc;
    },
    act: (bloc) => bloc.add(const SceneStarted(tmdbId: 1, initialTimestampMs: 2000)),
    expect: () => [
      const SceneLoading(),
      isA<SceneLoaded>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'auto-downloads subtitles and emits loaded',
    build: () {
      session.subtitleDocument = null;
      when(() => subtitleRepository.getCachedForTitle(any()))
          .thenAnswer((_) async => null);
      when(
        () => subtitleRepository.ensureSubtitleForTitle(
          tmdbId: 1,
          mediaType: MediaType.movie,
        ),
      ).thenAnswer((_) async => Success(document));
      when(
        () => repository.getContext(
          subtitles: document,
          cast: const [],
          timestampMs: 0,
          titleLabel: 'Matrix',
        ),
      ).thenAnswer((_) async => Success(context));
      return SceneBloc(repository, subtitleRepository, session);
    },
    act: (bloc) => bloc.add(const SceneStarted(tmdbId: 1)),
    expect: () => [
      const SceneLoading(),
      isA<SceneLoaded>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'emits failure when auto-download fails',
    build: () {
      session.subtitleDocument = null;
      when(() => subtitleRepository.getCachedForTitle(any()))
          .thenAnswer((_) async => null);
      when(
        () => subtitleRepository.ensureSubtitleForTitle(
          tmdbId: 1,
          mediaType: MediaType.movie,
        ),
      ).thenAnswer(
        (_) async => const Error(NotFoundFailure('No English SRT subtitles found')),
      );
      return SceneBloc(repository, subtitleRepository, session);
    },
    act: (bloc) => bloc.add(const SceneStarted(tmdbId: 1)),
    expect: () => [
      const SceneLoading(),
      isA<SceneFailure>(),
    ],
  );
}
