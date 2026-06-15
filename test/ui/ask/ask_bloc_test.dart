import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';

class MockAskRepository extends Mock implements AskRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockUsageLimitService extends Mock implements UsageLimitService {}

class MockUser extends Mock implements User {}

void main() {
  late MockAskRepository repository;
  late MockAuthService authService;
  late MockUsageLimitService usageLimitService;

  final context = SceneContext(
    timestampMs: 1000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    dialogueText: 'Neo habla',
    askDialogueText: 'Neo habla',
    priorDialogueText: '',
  );

  setUp(() {
    repository = MockAskRepository();
    authService = MockAuthService();
    usageLimitService = MockUsageLimitService();
    when(() => authService.currentUser).thenReturn(null);
    when(() => usageLimitService.canAskAnonymously()).thenReturn(true);
    when(() => usageLimitService.recordAnonymousQuestion()).thenReturn(null);
  });

  AskBloc createBloc() => AskBloc(
        repository,
        authService,
        usageLimitService,
      )..add(AskStarted(context));
  blocTest<AskBloc, AskState>(
    'emits answer on success',
    skip: 1,
    build: () {
      when(
        () => repository.ask(
          context: context,
          question: '¿Quién está?',
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: '¿Quién está?', answer: 'Neo'),
        ),
      );
      return createBloc();
    },
    act: (bloc) => bloc.add(const AskQuestionSubmitted('¿Quién está?')),
    expect: () => [
      const AskAnswering('¿Quién está?'),
      isA<AskAnswered>(),
    ],
    verify: (_) {
      verify(() => usageLimitService.recordAnonymousQuestion()).called(1);
    },
  );

  blocTest<AskBloc, AskState>(
    'blocks fourth anonymous question',
    skip: 1,
    build: () {
      when(() => usageLimitService.canAskAnonymously()).thenReturn(false);
      return createBloc();
    },
    act: (bloc) => bloc.add(const AskQuestionSubmitted('¿Cuarta?')),
    expect: () => [const AskAuthRequired()],
    verify: (_) {
      verifyNever(() => usageLimitService.recordAnonymousQuestion());
    },
  );

  blocTest<AskBloc, AskState>(
    'allows questions when authenticated without recording usage',
    skip: 1,
    build: () {
      final user = MockUser();
      when(() => authService.currentUser).thenReturn(user);
      when(
        () => repository.ask(
          context: context,
          question: '¿Quién está?',
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: '¿Quién está?', answer: 'Neo'),
        ),
      );
      return createBloc();
    },
    act: (bloc) => bloc.add(const AskQuestionSubmitted('¿Quién está?')),
    expect: () => [
      const AskAnswering('¿Quién está?'),
      isA<AskAnswered>(),
    ],
    verify: (_) {
      verifyNever(() => usageLimitService.recordAnonymousQuestion());
      verifyNever(() => usageLimitService.canAskAnonymously());
    },
  );

  blocTest<AskBloc, AskState>(
    'resets to initial on context update and uses new context',
    build: () => createBloc(),
    act: (bloc) async {
      when(
        () => repository.ask(
          context: context,
          question: '¿Quién está?',
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: '¿Quién está?', answer: 'Neo'),
        ),
      );
      bloc.add(const AskQuestionSubmitted('¿Quién está?'));
      await bloc.stream.firstWhere((state) => state is AskAnswered);

      const updatedContext = SceneContext(
        timestampMs: 5000,
        sceneBeforeSeconds: 120,
        sceneAfterSeconds: 30,
        dialogueText: 'Trinity habla',
        askDialogueText: 'Trinity habla',
        priorDialogueText: 'Neo habla',
      );
      when(
        () => repository.ask(
          context: updatedContext,
          question: '¿Qué pasa?',
          model: GeminiModel.defaultModel,
        ),
      ).thenAnswer(
        (_) async => const Success(
          SceneAnswer(question: '¿Qué pasa?', answer: 'Algo ocurre'),
        ),
      );
      bloc.add(const AskContextUpdated(updatedContext));
      bloc.add(const AskQuestionSubmitted('¿Qué pasa?'));
    },
    expect: () => [
      const AskInitial(),
      const AskAnswering('¿Quién está?'),
      isA<AskAnswered>(),
      const AskInitial(),
      const AskAnswering('¿Qué pasa?'),
      isA<AskAnswered>(),
    ],
  );
}
