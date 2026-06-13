import 'package:firebase_ai/firebase_ai.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

class FirebaseAiAskService implements AskService {
  FirebaseAiAskService({GenerativeModel? model, LocalStubAskService? fallback})
      : _model = model ??
            FirebaseAI.googleAI().generativeModel(
              model: modelId,
              systemInstruction: Content.system(_systemInstruction),
            ),
        _fallback = fallback ?? LocalStubAskService();

  static const modelId = 'gemini-2.5-flash';

  final GenerativeModel _model;
  final LocalStubAskService _fallback;

  static const _systemInstruction = '''
Eres un asistente que explica escenas concretas de películas y series en un momento exacto del vídeo.

Reglas estrictas:
- Responde SOLO sobre la escena seleccionada en el momento indicado, no sobre la película en general.
- Basa tu respuesta principalmente en el diálogo de la escena seleccionada (2 minutos antes hasta 30 segundos después del momento indicado).
- Usa el contexto previo únicamente para entender referencias; no lo resumas ni describas la trama completa.
- Usa SOLO la información proporcionada; no inventes tramas.
- NO describas eventos posteriores al momento seleccionado.
- Responde en el idioma de la pregunta del usuario.
- Si la escena seleccionada no tiene información suficiente, dilo claramente.
''';

  @override
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
  }) async {
    try {
      final response = await _model.generateContent([
        Content.text(buildAskPromptContent(context, question)),
      ]);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
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
          modelId: modelId,
        ),
      );
    } catch (_) {
      final fallback = await _fallback.ask(context: context, question: question);
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
  }
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

Contexto previo (diálogo desde el inicio hasta el momento seleccionado; solo para referencias, NO para resumir):
$priorDialogue

Personajes detectados en la escena: ${characters.isEmpty ? 'ninguno' : characters}

Pregunta: $question

Responde centrándote en lo que ocurre en la ESCENA SELECCIONADA en el momento indicado.
''';
}
