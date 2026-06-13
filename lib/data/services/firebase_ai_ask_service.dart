import 'package:firebase_ai/firebase_ai.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

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
Eres un asistente que explica escenas de películas y series.
Reglas estrictas:
- Usa SOLO el diálogo y los personajes proporcionados.
- NO inventes eventos posteriores al timestamp.
- NO des spoilers de tramas futuras.
- Responde en el idioma de la pregunta del usuario.
- Si no hay información suficiente, dilo claramente.
''';

  @override
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
  }) async {
    try {
      final characters = context.characters
          .map((c) => c.castMember.characterName)
          .join(', ');

      final response = await _model.generateContent([
        Content.text('''
Diálogo de la escena:
${context.dialogueText}

Personajes detectados: ${characters.isEmpty ? 'ninguno' : characters}

Pregunta: $question
'''),
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
  final characters = context.characters
      .map((c) => c.castMember.characterName)
      .join(', ');
  return '''
Diálogo de la escena:
${context.dialogueText}

Personajes detectados: ${characters.isEmpty ? 'ninguno' : characters}

Pregunta: $question
''';
}
