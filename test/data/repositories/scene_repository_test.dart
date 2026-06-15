import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/services/scene_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/dialogue_line.dart';
import 'package:storypilot/domain/result.dart';

class MockSceneFunctionsClient extends Mock implements SceneFunctionsClient {}

void main() {
  late MockSceneFunctionsClient client;
  late SceneRepository repository;

  const context = SceneContext(
    timestampMs: 2000,
    sceneBeforeSeconds: 120,
    sceneAfterSeconds: 30,
    activeLine: DialogueLine(startMs: 0, endMs: 5000, text: 'Hello'),
    dialogueText: 'Hello',
    askDialogueText: 'Hello',
    priorDialogueText: 'Hello',
  );

  setUp(() {
    client = MockSceneFunctionsClient();
    repository = SceneRepository(client);
  });

  test('prepareScene returns durationMs from backend', () async {
    when(
      () => client.getSceneContext(
        tmdbId: 1,
        mediaType: MediaType.movie,
        timestampMs: any(named: 'timestampMs'),
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer(
      (_) async => const GetSceneContextResult(durationMs: 7200000),
    );

    final result = await repository.prepareScene(
      tmdbId: 1,
      mediaType: MediaType.movie,
    );

    expect(result, isA<Success<int>>());
    expect((result as Success<int>).data, 7200000);
  });

  test('getContext returns parsed SceneContext', () async {
    when(
      () => client.getSceneContext(
        tmdbId: 1,
        mediaType: MediaType.movie,
        timestampMs: 2000,
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer(
      (_) async => const GetSceneContextResult(
        durationMs: 7200000,
        context: context,
      ),
    );

    final result = await repository.getContext(
      tmdbId: 1,
      mediaType: MediaType.movie,
      timestampMs: 2000,
    );

    expect(result, isA<Success<SceneContext>>());
    expect((result as Success<SceneContext>).data.dialogueText, 'Hello');
  });

  test('prepareScene fails when durationMs is zero', () async {
    when(
      () => client.getSceneContext(
        tmdbId: 1,
        mediaType: MediaType.movie,
        timestampMs: any(named: 'timestampMs'),
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer(
      (_) async => const GetSceneContextResult(durationMs: 0),
    );

    final result = await repository.prepareScene(
      tmdbId: 1,
      mediaType: MediaType.movie,
    );

    expect(result, isA<Error<int>>());
    expect(
      (result as Error<int>).failure,
      isA<NotFoundFailure>(),
    );
  });

  test('prepareScene maps missing scene data to NotFoundFailure', () async {
    when(
      () => client.getSceneContext(
        tmdbId: 1,
        mediaType: MediaType.movie,
        timestampMs: any(named: 'timestampMs'),
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenThrow(
      Exception('[firebase_functions/unavailable] Scene dialogue not available'),
    );

    final result = await repository.prepareScene(
      tmdbId: 1,
      mediaType: MediaType.movie,
    );

    expect(result, isA<Error<int>>());
    expect(
      (result as Error<int>).failure.message,
      'No hay información de escena disponible para este título.',
    );
  });
}
