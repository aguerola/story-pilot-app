import 'package:cloud_functions/cloud_functions.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/title_preprocessing.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';

class EnsureTitlePlaybackResult {
  const EnsureTitlePlaybackResult({required this.durationMs});

  final int durationMs;
}

class GetSceneContextResult {
  const GetSceneContextResult({
    required this.durationMs,
    required this.context,
    this.brief,
  });

  final int durationMs;
  final SceneContext context;
  final SceneBrief? brief;
}

abstract class SceneFunctionsClient {
  Future<EnsureTitlePlaybackResult> ensureTitlePlayback({
    required int tmdbId,
    required MediaType mediaType,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  });

  Future<TitlePreprocessingResult> getTitlePreprocessing({
    required int tmdbId,
    required MediaType mediaType,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  });

  Future<GetSceneContextResult> getSceneContext({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
    GeminiModel model = GeminiModel.defaultModel,
  });
}

class FirebaseSceneFunctionsClient implements SceneFunctionsClient {
  FirebaseSceneFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  Map<String, dynamic> _titlePayload({
    required int tmdbId,
    required MediaType mediaType,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  }) {
    final payload = <String, dynamic>{
      'tmdbId': tmdbId,
      'type': mediaType == MediaType.movie ? 'movie' : 'episode',
    };
    if (titleLabel != null) payload['titleLabel'] = titleLabel;
    if (imdbId != null && imdbId.isNotEmpty) payload['imdbId'] = imdbId;
    if (mediaType == MediaType.tv && episode != null) {
      payload['parentTmdbId'] = tmdbId;
      payload['seasonNumber'] = episode.seasonNumber;
      payload['episodeNumber'] = episode.episodeNumber;
    }
    return payload;
  }

  @override
  Future<EnsureTitlePlaybackResult> ensureTitlePlayback({
    required int tmdbId,
    required MediaType mediaType,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  }) async {
    final payload = _titlePayload(
      tmdbId: tmdbId,
      mediaType: mediaType,
      titleLabel: titleLabel,
      imdbId: imdbId,
      episode: episode,
    );

    final result =
        await _functions.httpsCallable('ensureTitlePlayback').call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);
    return EnsureTitlePlaybackResult(
      durationMs: data['durationMs'] as int? ?? 0,
    );
  }

  @override
  Future<TitlePreprocessingResult> getTitlePreprocessing({
    required int tmdbId,
    required MediaType mediaType,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
  }) async {
    final payload = _titlePayload(
      tmdbId: tmdbId,
      mediaType: mediaType,
      titleLabel: titleLabel,
      imdbId: imdbId,
      episode: episode,
    );

    final result =
        await _functions.httpsCallable('getTitlePreprocessing').call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);
    final status = data['status'] as String?;
    if (status == 'ready') {
      return TitlePreprocessingResult.ready(
        durationMs: data['durationMs'] as int? ?? 0,
        titleLabel: data['titleLabel'] as String? ?? '',
        sceneCount: data['sceneCount'] as int? ?? 0,
        analysisVersion: data['analysisVersion'] as int? ?? 0,
        generatedAt: data['generatedAt'] as int? ?? 0,
      );
    }
    return const TitlePreprocessingResult.pending();
  }

  @override
  Future<GetSceneContextResult> getSceneContext({
    required int tmdbId,
    required MediaType mediaType,
    required int timestampMs,
    String? titleLabel,
    String? imdbId,
    TvEpisodeSelection? episode,
    GeminiModel model = GeminiModel.defaultModel,
  }) async {
    final payload = _titlePayload(
      tmdbId: tmdbId,
      mediaType: mediaType,
      titleLabel: titleLabel,
      imdbId: imdbId,
      episode: episode,
    );
    payload['timestampMs'] = timestampMs;
    payload['modelId'] = model.id;

    final result =
        await _functions.httpsCallable('getSceneContext').call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);
    final durationMs = data['durationMs'] as int? ?? 0;
    final rawContext = data['context'];
    if (rawContext is! Map) {
      throw StateError('getSceneContext response missing context');
    }
    final context = SceneContext.fromApiMap(
      Map<String, dynamic>.from(rawContext),
    );

    SceneBrief? brief;
    final rawBrief = data['brief'];
    if (rawBrief is Map) {
      final briefMap = Map<String, dynamic>.from(rawBrief);
      brief = SceneBrief.fromJson(briefMap).copyWith(
        usage: _usageFromMap(briefMap, model.id),
      );
    }

    return GetSceneContextResult(
      durationMs: durationMs,
      context: context,
      brief: brief,
    );
  }

  static AiUsage? _usageFromMap(Map<String, dynamic> data, String modelId) {
    final hasUsage = data['promptTokens'] != null ||
        data['responseTokens'] != null ||
        data['totalTokens'] != null;
    final usedBreakdown = data['usedBreakdown'];
    if (!hasUsage && usedBreakdown is! bool) return null;
    return AiUsage(
      promptTokens: data['promptTokens'] as int?,
      responseTokens: data['responseTokens'] as int?,
      thoughtsTokens: data['thoughtsTokens'] as int?,
      totalTokens: data['totalTokens'] as int?,
      modelId: (data['modelId'] as String?) ?? modelId,
      usedBreakdown: usedBreakdown is bool ? usedBreakdown : null,
    );
  }
}
