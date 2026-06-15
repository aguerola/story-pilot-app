import 'dart:developer' as developer;

import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/ask_functions_client.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

class CallableAskService implements AskService {
  CallableAskService({
    required AskFunctionsClient client,
    required TitleSessionHolder session,
    LocalStubAskService? fallback,
  })  : _client = client,
        _session = session,
        _fallback = fallback ?? LocalStubAskService();

  final AskFunctionsClient _client;
  final TitleSessionHolder _session;
  final LocalStubAskService _fallback;

  @override
  Future<Result<SceneBrief>> brief({
    required SceneContext context,
    required List<CastMember> cast,
    GeminiModel model = GeminiModel.defaultModel,
  }) async {
    final title = _session.titleDetail;
    if (title == null) {
      return _fallback.brief(context: context, cast: cast, model: model);
    }

    try {
      final data = await _client.sceneBrief(
        tmdbId: title.summary.id,
        mediaType: title.summary.mediaType,
        timestampMs: context.timestampMs,
        titleLabel: context.titleLabel ?? title.summary.displayLabel,
        episode: title.summary.mediaType == MediaType.tv
            ? _session.selectedEpisode
            : null,
        cast: cast
            .map((member) => {'characterName': member.characterName})
            .where((entry) => (entry['characterName'] as String).isNotEmpty)
            .toList(),
        modelId: model.id,
      );

      final summary = (data['summary'] as String?)?.trim() ?? '';
      if (summary.isEmpty) {
        return _fallback.brief(context: context, cast: cast, model: model);
      }

      return Success(
        SceneBrief(
          summary: summary,
          presentCharacterNames: _stringList(data['characters']),
          questions: _stringList(data['questions']),
          usage: _usageFromMap(data, model.id),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'brief generation failed, using fallback',
        name: 'CallableAskService',
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback.brief(context: context, cast: cast, model: model);
    }
  }

  @override
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
    GeminiModel model = GeminiModel.defaultModel,
  }) async {
    try {
      return await _generateAnswer(
        context: context,
        question: question,
        model: model,
      );
    } catch (error, stackTrace) {
      return _stubFallback(
        context: context,
        question: question,
        model: model,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result<SceneAnswer>> _generateAnswer({
    required SceneContext context,
    required String question,
    required GeminiModel model,
  }) async {
    final title = _session.titleDetail;
    if (title == null) {
      return const Error(NotFoundFailure('Title not available'));
    }

    final data = await _client.sceneAsk(
      tmdbId: title.summary.id,
      mediaType: title.summary.mediaType,
      timestampMs: context.timestampMs,
      titleLabel: context.titleLabel ?? title.summary.displayLabel,
      episode: title.summary.mediaType == MediaType.tv
          ? _session.selectedEpisode
          : null,
      question: question,
      modelId: model.id,
    );

    final answer = (data['answer'] as String?)?.trim();
    if (answer == null || answer.isEmpty) {
      developer.log(
        'sceneAsk returned empty text',
        name: 'CallableAskService',
      );
      return const Error(ServerFailure('Empty response from Gemini'));
    }

    return Success(
      SceneAnswer(
        question: question,
        answer: answer,
        sources: context.dialogueText.split('\n').take(2).toList(),
        promptTokens: data['promptTokens'] as int?,
        responseTokens: data['responseTokens'] as int?,
        thoughtsTokens: data['thoughtsTokens'] as int?,
        totalTokens: data['totalTokens'] as int?,
        modelId: (data['modelId'] as String?) ?? model.id,
      ),
    );
  }

  Future<Result<SceneAnswer>> _stubFallback({
    required SceneContext context,
    required String question,
    required GeminiModel model,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    developer.log(
      'sceneAsk failed, using fallback',
      name: 'CallableAskService',
      error: error,
      stackTrace: stackTrace,
    );
    final fallback = await _fallback.ask(
      context: context,
      question: question,
      model: model,
    );
    if (fallback is Success<SceneAnswer>) {
      return Success(
        SceneAnswer(
          question: question,
          answer:
              '${fallback.data.answer}\n\n(Respuesta de respaldo: AI no disponible)',
          sources: fallback.data.sources,
        ),
      );
    }
    return const Error(NetworkFailure('AI unavailable'));
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static AiUsage _usageFromMap(Map<String, dynamic> data, String modelId) {
    return AiUsage(
      promptTokens: data['promptTokens'] as int?,
      responseTokens: data['responseTokens'] as int?,
      thoughtsTokens: data['thoughtsTokens'] as int?,
      totalTokens: data['totalTokens'] as int?,
      modelId: (data['modelId'] as String?) ?? modelId,
    );
  }
}
