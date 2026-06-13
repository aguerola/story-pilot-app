import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_summary_cubit.dart';

class MockAskRepository extends Mock implements AskRepository {}

void main() {
  late MockAskRepository repository;

  const context = SceneContext(
    timestampMs: 1000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    dialogueText: 'Neo habla',
    askDialogueText: 'Neo habla',
    priorDialogueText: '',
    characters: [],
  );

  setUp(() {
    repository = MockAskRepository();
  });

  blocTest<SceneSummaryCubit, SceneSummaryState>(
    'emits loading then ready and always uses the Lite model',
    build: () {
      when(
        () => repository.ask(
          context: context,
          question: any(named: 'question'),
          model: GeminiModel.flashLite25,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: 'resumen', answer: 'Jake lidera a los Na\'vi.'),
        ),
      );
      return SceneSummaryCubit(repository);
    },
    act: (cubit) => cubit.summarize(context),
    expect: () => [
      const SceneSummaryLoading(),
      const SceneSummaryReady('Jake lidera a los Na\'vi.'),
    ],
    verify: (_) {
      verify(
        () => repository.ask(
          context: context,
          question: any(named: 'question'),
          model: GeminiModel.flashLite25,
        ),
      ).called(1);
    },
  );

  blocTest<SceneSummaryCubit, SceneSummaryState>(
    'emits failure when the request fails',
    build: () {
      when(
        () => repository.ask(
          context: context,
          question: any(named: 'question'),
          model: GeminiModel.flashLite25,
        ),
      ).thenAnswer((_) async => const Error(NetworkFailure('boom')));
      return SceneSummaryCubit(repository);
    },
    act: (cubit) => cubit.summarize(context),
    expect: () => [
      const SceneSummaryLoading(),
      isA<SceneSummaryFailure>(),
    ],
  );
}
