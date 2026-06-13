import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

class AskRepository {
  AskRepository(this._askService);

  final AskService _askService;

  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
    GeminiModel model = GeminiModel.defaultModel,
  }) {
    return _askService.ask(
      context: context,
      question: question,
      model: model,
    );
  }

  Future<Result<SceneBrief>> brief({
    required SceneContext context,
    required List<CastMember> cast,
    GeminiModel model = GeminiModel.defaultModel,
  }) {
    return _askService.brief(
      context: context,
      cast: cast,
      model: model,
    );
  }
}
