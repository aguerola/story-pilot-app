import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/services/scene_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
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

  const cast = [
    CastMember(
      id: 1,
      name: 'Actor',
      characterName: 'Hero',
      billingOrder: 0,
    ),
  ];

  setUp(() {
    client = MockSceneFunctionsClient();
    repository = SceneRepository(client);
  });

  setUpAll(() {
    registerFallbackValue(GeminiModel.defaultModel);
  });

  test('ensureTitlePlayback returns durationMs from backend', () async {
    when(
      () => client.ensureTitlePlayback(
        tmdbId: 1,
        mediaType: MediaType.movie,
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer(
      (_) async => const EnsureTitlePlaybackResult(durationMs: 7200000),
    );

    final result = await repository.ensureTitlePlayback(
      tmdbId: 1,
      mediaType: MediaType.movie,
    );

    expect(result, isA<Success<int>>());
    expect((result as Success<int>).data, 7200000);
  });

  test('getContext returns parsed SceneContext and brief', () async {
    when(
      () => client.getSceneContext(
        tmdbId: 1,
        mediaType: MediaType.movie,
        timestampMs: 2000,
        cast: cast,
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
        model: any(named: 'model'),
      ),
    ).thenAnswer(
      (_) async => const GetSceneContextResult(
        durationMs: 7200000,
        context: context,
        brief: SceneBrief(
          summary: 'Something happens.',
          presentCharacterNames: ['Hero'],
          questions: ['What now?'],
        ),
      ),
    );

    final result = await repository.getContext(
      tmdbId: 1,
      mediaType: MediaType.movie,
      timestampMs: 2000,
      cast: cast,
    );

    expect(result, isA<Success<SceneContextWithBrief>>());
    final data = (result as Success<SceneContextWithBrief>).data;
    expect(data.context.dialogueText, 'Hello');
    expect(data.brief?.summary, 'Something happens.');
  });

  test('ensureTitlePlayback fails when durationMs is zero', () async {
    when(
      () => client.ensureTitlePlayback(
        tmdbId: 1,
        mediaType: MediaType.movie,
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenAnswer(
      (_) async => const EnsureTitlePlaybackResult(durationMs: 0),
    );

    final result = await repository.ensureTitlePlayback(
      tmdbId: 1,
      mediaType: MediaType.movie,
    );

    expect(result, isA<Error<int>>());
    expect(
      (result as Error<int>).failure,
      isA<NotFoundFailure>(),
    );
  });

  test('ensureTitlePlayback maps missing scene data to NotFoundFailure', () async {
    when(
      () => client.ensureTitlePlayback(
        tmdbId: 1,
        mediaType: MediaType.movie,
        titleLabel: any(named: 'titleLabel'),
        imdbId: any(named: 'imdbId'),
        episode: any(named: 'episode'),
      ),
    ).thenThrow(
      Exception('[firebase_functions/unavailable] Scene dialogue not available'),
    );

    final result = await repository.ensureTitlePlayback(
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
