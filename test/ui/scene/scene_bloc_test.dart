import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
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

void main() {
  late MockSceneRepository repository;
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
    windowSeconds: 30,
    activeLine: document.lines.first,
    dialogueText: 'Neo habla con Morpheus',
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
    bloc = SceneBloc(repository, session);
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
          windowSeconds: 30,
        ),
      ).thenAnswer((_) async => Success(context));
      return bloc;
    },
    act: (bloc) => bloc.add(const SceneStarted(initialTimestampMs: 2000)),
    expect: () => [
      const SceneLoading(),
      isA<SceneLoaded>(),
    ],
  );

  blocTest<SceneBloc, SceneState>(
    'emits missing data without subtitles',
    build: () {
      session.subtitleDocument = null;
      return SceneBloc(repository, session);
    },
    act: (bloc) => bloc.add(const SceneStarted()),
    expect: () => [const SceneMissingData()],
  );
}
