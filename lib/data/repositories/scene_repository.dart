import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/scene_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';

class SceneContextWithBrief {
  const SceneContextWithBrief({
    required this.context,
    this.brief,
  });

  final SceneContext context;
  final SceneBrief? brief;
}

class SceneRepository {
  SceneRepository(this._client);

  final SceneFunctionsClient _client;

  Future<Result<int>> ensureTitlePlayback({
    required int tmdbId,
    required MediaType mediaType,
    TvEpisodeSelection? episode,
    String? titleLabel,
    String? imdbId,
  }) async {
    try {
      final result = await _client.ensureTitlePlayback(
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

  Future<Result<SceneContextWithBrief>> getContext({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    TvEpisodeSelection? episode,
    String? titleLabel,
    String? imdbId,
    GeminiModel model = GeminiModel.defaultModel,
  }) async {
    try {
      final result = await _client.getSceneContext(
        tmdbId: tmdbId,
        mediaType: mediaType,
        timestampMs: timestampMs,
        episode: episode,
        titleLabel: titleLabel,
        imdbId: imdbId,
        model: model,
      );
      return Success(
        SceneContextWithBrief(
          context: result.context,
          brief: result.brief,
        ),
      );
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
