import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';

class MockAskRepository extends Mock implements AskRepository {}

void main() {
  late MockAskRepository repository;
  late AskBloc bloc;

  final context = SceneContext(
    timestampMs: 1000,
    windowSeconds: 30,
    dialogueText: 'Neo habla',
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
    repository = MockAskRepository();
    bloc = AskBloc(repository)..add(AskStarted(context));
  });

  tearDown(() => bloc.close());

  blocTest<AskBloc, AskState>(
    'emits answer on success',
    build: () {
      when(
        () => repository.ask(context: context, question: '¿Quién está?'),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: '¿Quién está?', answer: 'Neo'),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const AskQuestionSubmitted('¿Quién está?')),
    expect: () => [
      const AskAnswering('¿Quién está?'),
      isA<AskAnswered>(),
    ],
  );
}
