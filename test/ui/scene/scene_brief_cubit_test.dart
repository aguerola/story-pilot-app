import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_brief_cubit.dart';

class MockAskRepository extends Mock implements AskRepository {}

void main() {
  late MockAskRepository repository;

  const context = SceneContext(
    timestampMs: 1000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    dialogueText: 'Jake Sully will go first.',
    askDialogueText: 'Jake Sully will go first.',
    priorDialogueText: '',
    characters: [],
  );

  const cast = [
    CastMember(
      id: 1,
      name: 'Sam Worthington',
      characterName: 'Jake Sully',
      billingOrder: 0,
    ),
    CastMember(
      id: 2,
      name: 'Zoe Saldaña',
      characterName: 'Neytiri',
      billingOrder: 1,
    ),
  ];

  setUp(() {
    repository = MockAskRepository();
  });

  blocTest<SceneBriefCubit, SceneBriefState>(
    'resolves AI character names to TMDB cast and always uses Lite',
    build: () {
      when(
        () => repository.brief(
          context: context,
          cast: cast,
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneBrief(
            summary: 'Jake lidera al grupo.',
            // Includes a non-cast name that must be dropped.
            presentCharacterNames: ['Jake Sully', 'Na\'vi'],
            questions: ['¿Qué pretende Jake?'],
          ),
        ),
      );
      return SceneBriefCubit(repository);
    },
    act: (cubit) => cubit.load(context, cast),
    expect: () => [
      const SceneBriefLoading(),
      isA<SceneBriefReady>()
          .having((s) => s.summary, 'summary', 'Jake lidera al grupo.')
          .having(
            (s) => s.characters.map((c) => c.castMember.characterName).toList(),
            'character names',
            ['Jake Sully'],
          )
          .having((s) => s.questions, 'questions', ['¿Qué pretende Jake?']),
    ],
    verify: (_) {
      verify(
        () => repository.brief(
          context: context,
          cast: cast,
          model: GeminiModel.defaultModel,
        ),
      ).called(1);
    },
  );

  blocTest<SceneBriefCubit, SceneBriefState>(
    'emits failure when the request fails',
    build: () {
      when(
        () => repository.brief(
          context: context,
          cast: cast,
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer((_) async => const Error(NetworkFailure('boom')));
      return SceneBriefCubit(repository);
    },
    act: (cubit) => cubit.load(context, cast),
    expect: () => [
      const SceneBriefLoading(),
      isA<SceneBriefFailure>(),
    ],
  );
}
