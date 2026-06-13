import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

class AskRepository {
  AskRepository(this._askService);

  final AskService _askService;

  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
  }) {
    return _askService.ask(context: context, question: question);
  }
}
