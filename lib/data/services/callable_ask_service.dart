import 'dart:developer' as developer;

import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/ask_functions_client.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

class CallableAskService implements AskService {
  CallableAskService({
    required AskFunctionsClient client,
    required TitleSessionHolder session,
  })  : _client = client,
        _session = session;

  final AskFunctionsClient _client;
  final TitleSessionHolder _session;

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
      developer.log(
        'sceneAsk failed',
        name: 'CallableAskService',
        error: error,
        stackTrace: stackTrace,
      );
      return Error(_mapError(error));
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
      return const Error(ServerFailure('Empty response from AI'));
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

  Failure _mapError(Object error) {
    final message = error.toString();
    if (message.contains('unauthenticated') || message.contains('permission')) {
      return AuthRequiredFailure(message);
    }
    return NetworkFailure(message);
  }
}
