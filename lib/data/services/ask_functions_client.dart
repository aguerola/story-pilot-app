import 'package:cloud_functions/cloud_functions.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';

abstract class AskFunctionsClient {
  Future<Map<String, dynamic>> sceneAsk({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    required String question,
    String? titleLabel,
    TvEpisodeSelection? episode,
    String? modelId,
  });

  Future<Map<String, dynamic>> sceneBrief({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    required List<Map<String, dynamic>> cast,
    String? titleLabel,
    TvEpisodeSelection? episode,
    String? modelId,
  });
}

class FirebaseAskFunctionsClient implements AskFunctionsClient {
  FirebaseAskFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  Map<String, dynamic> _titlePayload({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    String? titleLabel,
    TvEpisodeSelection? episode,
  }) {
    final payload = <String, dynamic>{
      'tmdbId': tmdbId,
      'type': mediaType == MediaType.movie ? 'movie' : 'episode',
      'timestampMs': timestampMs,
    };
    if (titleLabel != null) payload['titleLabel'] = titleLabel;
    if (mediaType == MediaType.tv && episode != null) {
      payload['parentTmdbId'] = tmdbId;
      payload['seasonNumber'] = episode.seasonNumber;
      payload['episodeNumber'] = episode.episodeNumber;
    }
    return payload;
  }

  @override
  Future<Map<String, dynamic>> sceneAsk({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    required String question,
    String? titleLabel,
    TvEpisodeSelection? episode,
    String? modelId,
  }) async {
    final payload = _titlePayload(
      tmdbId: tmdbId,
      mediaType: mediaType,
      timestampMs: timestampMs,
      titleLabel: titleLabel,
      episode: episode,
    );
    payload['question'] = question;
    if (modelId != null) payload['modelId'] = modelId;
    final result = await _functions.httpsCallable('sceneAsk').call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<Map<String, dynamic>> sceneBrief({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    required List<Map<String, dynamic>> cast,
    String? titleLabel,
    TvEpisodeSelection? episode,
    String? modelId,
  }) async {
    final payload = _titlePayload(
      tmdbId: tmdbId,
      mediaType: mediaType,
      timestampMs: timestampMs,
      titleLabel: titleLabel,
      episode: episode,
    );
    payload['cast'] = cast;
    if (modelId != null) payload['modelId'] = modelId;
    final result = await _functions.httpsCallable('sceneBrief').call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }
}
