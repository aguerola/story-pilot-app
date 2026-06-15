import 'package:storypilot/data/services/scene_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';

class SceneRepository {
  SceneRepository(this._client);

  final SceneFunctionsClient _client;

  Future<Result<int>> prepareScene({
    required int tmdbId,
    required MediaType mediaType,
    TvEpisodeSelection? episode,
    String? titleLabel,
    String? imdbId,
  }) async {
    try {
      final result = await _client.getSceneContext(
        tmdbId: tmdbId,
        mediaType: mediaType,
        episode: episode,
        titleLabel: titleLabel,
        imdbId: imdbId,
      );
      if (result.durationMs <= 0) {
        return const Error(
          NotFoundFailure(
            'No hay información de escena disponible para este título.',
          ),
        );
      }
      return Success(result.durationMs);
    } catch (error) {
      return Error(_mapSceneError(error));
    }
  }

  Future<Result<SceneContext>> getContext({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    TvEpisodeSelection? episode,
    String? titleLabel,
    String? imdbId,
  }) async {
    try {
      final result = await _client.getSceneContext(
        tmdbId: tmdbId,
        mediaType: mediaType,
        timestampMs: timestampMs,
        episode: episode,
        titleLabel: titleLabel,
        imdbId: imdbId,
      );
      final context = result.context;
      if (context == null) {
        return const Error(
          NotFoundFailure(
            'No se pudo cargar la información de la escena.',
          ),
        );
      }
      return Success(context);
    } catch (error) {
      return Error(_mapSceneError(error));
    }
  }

  Failure _mapSceneError(Object error) {
    final message = error.toString();
    if (message.contains('Scene dialogue not available')) {
      return const NotFoundFailure(
        'No hay información de escena disponible para este título.',
      );
    }
    return NetworkFailure(message);
  }
}
