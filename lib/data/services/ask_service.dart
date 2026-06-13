import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_brief.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

abstract class AskService {
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
    GeminiModel model = GeminiModel.defaultModel,
  });

  /// Single structured call that returns a scene summary, the present cast
  /// members, and suggested questions. Used for the free auto-brief on load.
  Future<Result<SceneBrief>> brief({
    required SceneContext context,
    required List<CastMember> cast,
    GeminiModel model = GeminiModel.defaultModel,
  });
}
