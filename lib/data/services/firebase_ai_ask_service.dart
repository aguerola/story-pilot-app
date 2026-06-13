import 'dart:developer' as developer;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

class FirebaseAiAskService implements AskService {
  FirebaseAiAskService({
    LocalStubAskService? fallback,
  }) : _fallback = fallback ?? LocalStubAskService();

  static const model = GeminiModel.defaultModel;

  final LocalStubAskService _fallback;
  final Map<GeminiModel, GenerativeModel> _models = {};

  GenerativeModel _modelFor(GeminiModel geminiModel) {
    return _models.putIfAbsent(
      geminiModel,
      () => FirebaseAI.googleAI().generativeModel(
        model: geminiModel.id,
        systemInstruction: Content.system(_systemInstruction),
      ),
    );
  }

  static const _systemInstruction = '''
Eres un asistente que explica escenas concretas de películas y series en un momento exacto del vídeo.

Reglas:
- Ancla tu respuesta en la escena seleccionada en el momento indicado; el diálogo proporcionado es la fuente de verdad sobre lo que ocurre ahí.
- Enriquece con tu conocimiento general de la película o serie (personajes, relaciones, trama previa, referencias culturales, actores) cuando ayude a responder mejor.
- Prioriza el diálogo de la escena seleccionada (2 minutos antes hasta 30 segundos después del momento indicado) para describir lo que pasa en ese instante.
- Usa el contexto previo de subtítulos para entender referencias concretas en la escena.
- NO describas eventos posteriores al momento seleccionado (evita spoilers).
- Si algo no está claro en la escena, puedes inferirlo con tu conocimiento.
- La lista de personajes detectados es heurística y puede estar incompleta.
- Responde en el idioma de la pregunta del usuario.
''';

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
      if (isQuotaExceeded(error)) {
        var quotaMessage = quotaErrorMessage(error);
        developer.log(
          quotaMessage,
          name: 'FirebaseAiAskService',
          error: error,
          stackTrace: stackTrace,
        );

        if (model == GeminiModel.flash25) {
          try {
            return await _generateAnswer(
              context: context,
              question: question,
              model: GeminiModel.flashLite25,
            );
          } catch (liteError, liteStackTrace) {
            if (!isQuotaExceeded(liteError)) {
              return _stubFallback(
                context: context,
                question: question,
                model: model,
                error: liteError,
                stackTrace: liteStackTrace,
              );
            }
            developer.log(
              quotaErrorMessage(liteError),
              name: 'FirebaseAiAskService',
              error: liteError,
              stackTrace: liteStackTrace,
            );
            quotaMessage = quotaErrorMessage(liteError);
          }
        }

        final retryAfterSeconds = parseQuotaRetrySeconds(quotaMessage);
        return Error(
          QuotaFailure(
            quotaFailureMessage(
              modelLabel: model.shortLabel,
              retryAfterSeconds: retryAfterSeconds,
            ),
            retryAfterSeconds: retryAfterSeconds,
          ),
        );
      }

      return _stubFallback(
        context: context,
        question: question,
        model: model,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result<SceneAnswer>> _stubFallback({
    required SceneContext context,
    required String question,
    required GeminiModel model,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    developer.log(
      'generateContent failed, using fallback',
      name: 'FirebaseAiAskService',
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
              '${fallback.data.answer}\n\n(Respuesta de respaldo: Firebase AI no disponible)',
          sources: fallback.data.sources,
        ),
      );
    }
    return const Error(NetworkFailure('Firebase AI unavailable'));
  }

  Future<Result<SceneAnswer>> _generateAnswer({
    required SceneContext context,
    required String question,
    required GeminiModel model,
  }) async {
    final response = await _modelFor(model).generateContent([
      Content.text(buildAskPromptContent(context, question)),
    ]);

    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      developer.log(
        'Gemini returned empty text (promptFeedback: ${response.promptFeedback})',
        name: 'FirebaseAiAskService',
      );
      return const Error(ServerFailure('Empty response from Gemini'));
    }

    final usage = response.usageMetadata;

    return Success(
      SceneAnswer(
        question: question,
        answer: text,
        sources: context.dialogueText.split('\n').take(2).toList(),
        promptTokens: usage?.promptTokenCount,
        responseTokens: usage?.candidatesTokenCount,
        thoughtsTokens: usage?.thoughtsTokenCount,
        totalTokens: usage?.totalTokenCount,
        modelId: model.id,
      ),
    );
  }
}

bool isQuotaExceeded(Object error) {
  if (error is FirebaseAIException) {
    return error.message.toLowerCase().contains('quota');
  }
  return error.toString().toLowerCase().contains('quota exceeded');
}

String quotaErrorMessage(Object error) {
  if (error is FirebaseAIException) return error.message;
  return error.toString();
}

int? parseQuotaRetrySeconds(String message) {
  final match = RegExp(r'retry in (\d+(?:\.\d+)?)s', caseSensitive: false)
      .firstMatch(message);
  if (match == null) return null;
  return double.parse(match.group(1)!).ceil();
}

String quotaFailureMessage({
  required String modelLabel,
  int? retryAfterSeconds,
}) {
  final retryHint = retryAfterSeconds == null
      ? 'Espera un momento e inténtalo de nuevo.'
      : 'Espera unos ${retryAfterSeconds}s e inténtalo de nuevo.';
  return 'Has alcanzado el límite de peticiones de Gemini ($modelLabel). '
      '$retryHint También puedes cambiar a Lite en el selector de modelo.';
}

String buildAskPromptContent(SceneContext context, String question) {
  final timestamp = formatMsToTimestamp(context.timestampMs);
  final activeSubtitle = context.activeLine?.text.trim();
  final characters = context.characters
      .map((c) => c.castMember.characterName)
      .join(', ');

  final activeLineSection = activeSubtitle != null && activeSubtitle.isNotEmpty
      ? 'Subtítulo en ese instante: "$activeSubtitle"\n\n'
      : '';

  final sceneDialogue = context.dialogueText.trim().isEmpty
      ? '(sin diálogo en esta ventana)'
      : context.dialogueText;

  final priorDialogue = context.priorDialogueText.trim().isEmpty
      ? '(sin diálogo previo)'
      : context.priorDialogueText;

  return '''
Momento seleccionado: $timestamp
${activeLineSection}Escena seleccionada (diálogo ${context.sceneWindowLabel} del momento):
$sceneDialogue

Contexto previo (todos los subtítulos desde el inicio hasta el momento seleccionado):
$priorDialogue

Personajes detectados automáticamente (lista incompleta, puede haber más): ${characters.isEmpty ? 'ninguno' : characters}

Pregunta: $question

Responde anclándote en la ESCENA SELECCIONADA en el momento indicado. Usa el diálogo como referencia principal y complementa con tu conocimiento de la película o serie cuando enriquezca la respuesta. No spoilers de eventos posteriores al momento seleccionado.
''';
}
