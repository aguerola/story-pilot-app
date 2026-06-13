import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
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
  final Map<GeminiModel, GenerativeModel> _briefModels = {};

  GenerativeModel _modelFor(GeminiModel geminiModel) {
    return _models.putIfAbsent(
      geminiModel,
      () => FirebaseAI.googleAI().generativeModel(
        model: geminiModel.id,
        systemInstruction: Content.system(_systemInstruction),
      ),
    );
  }

  GenerativeModel _briefModelFor(GeminiModel geminiModel) {
    return _briefModels.putIfAbsent(
      geminiModel,
      () => FirebaseAI.googleAI().generativeModel(
        model: geminiModel.id,
        systemInstruction: Content.system(_systemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'summary': Schema.string(),
              'characters': Schema.array(items: Schema.string()),
              'questions': Schema.array(items: Schema.string()),
            },
          ),
        ),
      ),
    );
  }

  @override
  Future<Result<SceneBrief>> brief({
    required SceneContext context,
    required List<CastMember> cast,
    GeminiModel model = GeminiModel.defaultModel,
  }) async {
    try {
      final response = await _briefModelFor(model).generateContent([
        Content.text(buildBriefPromptContent(context, cast)),
      ]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return _fallback.brief(context: context, cast: cast, model: model);
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      final usage = response.usageMetadata;
      return Success(
        SceneBrief.fromJson(json).copyWith(
          usage: AiUsage(
            promptTokens: usage?.promptTokenCount,
            responseTokens: usage?.candidatesTokenCount,
            thoughtsTokens: usage?.thoughtsTokenCount,
            totalTokens: usage?.totalTokenCount,
            modelId: model.id,
          ),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'brief generation failed, using fallback',
        name: 'FirebaseAiAskService',
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback.brief(context: context, cast: cast, model: model);
    }
  }

  static const _systemInstruction = '''
Eres un asistente que explica escenas concretas de películas y series en un momento exacto del vídeo.

Reglas:
- Ancla tu respuesta en la escena seleccionada en el momento indicado; el diálogo proporcionado es la fuente de verdad sobre lo que ocurre ahí.
- Enriquece con tu conocimiento general de la película o serie (personajes, relaciones, trama previa, referencias culturales, actores) cuando ayude a responder mejor.
- Prioriza el diálogo de la escena seleccionada (hasta el momento indicado) para describir lo que pasa en ese instante.
- Usa el contexto previo de subtítulos para entender referencias concretas en la escena.
- REGLA CRÍTICA ANTI-SPOILER: no reveles NADA que ocurra después del momento seleccionado. No anticipes giros, finales, muertes, traiciones ni desenlaces, aunque conozcas la película o serie. El usuario está viéndola en ese instante.
- Si algo no está claro en la escena, puedes inferirlo con tu conocimiento, pero sin adelantar acontecimientos futuros.
- La lista de personajes detectados es heurística y puede estar incompleta.
- Responde en el idioma de la pregunta del usuario.
- Responde anclándote en la ESCENA SELECCIONADA en el momento indicado. Usa el diálogo como referencia principal y complementa con tu conocimiento de la película o serie cuando enriquezca la respuesta.
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

String buildBriefPromptContent(SceneContext context, List<CastMember> cast) {
  final timestamp = formatMsToTimestamp(context.timestampMs);
  final priorDialogue = context.priorDialogueText.trim().isEmpty
      ? '(sin diálogo previo)'
      : context.priorDialogueText;
  final castList = cast.isEmpty
      ? '(reparto no disponible)'
      : cast.map((c) => c.characterName).where((n) => n.isNotEmpty).join(', ');

  final titleSection = context.titleLabel != null
      ? 'Título: ${context.titleLabel}\n\n'
      : '';

  // Deliberately omit any dialogue after the selected moment to avoid spoilers.
  return '''
${titleSection}Contexto previo (todos los subtítulos desde el inicio hasta el momento seleccionado):
$priorDialogue

Momento seleccionado: $timestamp

Reparto disponible (nombres de personaje de TMDB): $castList

Tarea: a partir del diálogo y tu conocimiento de la obra, devuelve un JSON con:
- "summary": 2-3 frases explicando qué está ocurriendo en este momento, sin revelar nada posterior (sin spoilers).
- "characters": los personajes del reparto disponible que están PRESENTES en la escena en este momento (no solo mencionados). Usa exactamente los nombres del reparto disponible. Si no hay ninguno claro, lista vacía.
- "questions": 3-4 preguntas breves y específicas que el espectador podría querer hacer sobre esta escena.
''';
}

String buildAskPromptContent(SceneContext context, String question) {
  final timestamp = formatMsToTimestamp(context.timestampMs);
  final activeSubtitle = context.activeLine?.text.trim();
  final characters = context.characters
      .map((c) => c.castMember.characterName)
      .join(', ');

  final titleSection = context.titleLabel != null
      ? 'Título: ${context.titleLabel}\n\n'
      : '';

  final priorDialogue = context.priorDialogueText.trim().isEmpty
      ? '(sin diálogo previo)'
      : context.priorDialogueText;

  final activeLineSection = activeSubtitle != null && activeSubtitle.isNotEmpty
      ? 'Subtítulo en ese instante: "$activeSubtitle"\n'
      : '';

  // Deliberately omit any dialogue after the selected moment to avoid spoilers.
  return '''
${titleSection}Contexto previo (todos los subtítulos desde el inicio hasta el momento seleccionado):
$priorDialogue

Momento seleccionado: $timestamp
${activeLineSection}Personajes detectados automáticamente (lista incompleta, puede haber más): ${characters.isEmpty ? 'ninguno' : characters}

Pregunta: $question
''';
}
