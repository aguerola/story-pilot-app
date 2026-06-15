import 'package:cloud_functions/cloud_functions.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';

class GetSceneContextResult {
  const GetSceneContextResult({
    required this.durationMs,
    this.context,
  });

  final int durationMs;
  final SceneContext? context;
}

abstract class SceneFunctionsClient {
  Future<GetSceneContextResult> getSceneContext({
    required int tmdbId,
    required MediaType mediaType,
    int? timestampMs,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  });
}

class FirebaseSceneFunctionsClient implements SceneFunctionsClient {
  FirebaseSceneFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  @override
  Future<GetSceneContextResult> getSceneContext({
    required int tmdbId,
    required MediaType mediaType,
    int? timestampMs,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  }) async {
    final payload = <String, dynamic>{
      'tmdbId': tmdbId,
      'type': mediaType == MediaType.movie ? 'movie' : 'episode',
    };
    if (titleLabel != null) payload['titleLabel'] = titleLabel;
    if (imdbId != null && imdbId.isNotEmpty) payload['imdbId'] = imdbId;
    if (timestampMs != null && timestampMs > 0) {
      payload['timestampMs'] = timestampMs;
    }
    if (mediaType == MediaType.tv && episode != null) {
      payload['parentTmdbId'] = tmdbId;
      payload['seasonNumber'] = episode.seasonNumber;
      payload['episodeNumber'] = episode.episodeNumber;
    }

    final result =
        await _functions.httpsCallable('getSceneContext').call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);
    final durationMs = data['durationMs'] as int? ?? 0;
    final rawContext = data['context'];
    SceneContext? context;
    if (rawContext is Map) {
      context = SceneContext.fromApiMap(
        Map<String, dynamic>.from(rawContext),
      );
    }
    return GetSceneContextResult(durationMs: durationMs, context: context);
  }
}
