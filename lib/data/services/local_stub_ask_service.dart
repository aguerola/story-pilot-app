import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

class LocalStubAskService implements AskService {
  @override
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
  }) async {
    final lower = question.toLowerCase();
    if (lower.contains('quién') ||
        lower.contains('quien') ||
        lower.contains('who')) {
      if (context.characters.isEmpty) {
        return Success(
          SceneAnswer(
            question: question,
            answer: 'No se detectaron personajes en esta escena.',
          ),
        );
      }
      final names = context.characters
          .map((c) => c.castMember.characterName)
          .join(', ');
      return Success(
        SceneAnswer(
          question: question,
          answer: 'Personajes detectados en la escena: $names',
          sources: [context.dialogueText.split('\n').firstOrNull ?? ''],
        ),
      );
    }

    if (lower.contains('qué') ||
        lower.contains('que') ||
        lower.contains('what')) {
      final summary = context.dialogueText
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(3)
          .join(' ');
      return Success(
        SceneAnswer(
          question: question,
          answer: summary.isEmpty
              ? 'No hay diálogo en la ventana temporal seleccionada.'
              : 'En esta escena ocurre lo siguiente: $summary',
          sources: context.dialogueText.split('\n').take(2).toList(),
        ),
      );
    }

    return Success(
      SceneAnswer(
        question: question,
        answer:
            'Puedo responder preguntas sobre "quién" está en la escena o "qué" ocurre según el diálogo disponible.',
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
