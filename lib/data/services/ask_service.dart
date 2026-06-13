import 'package:storypilot/domain/models/scene_answer.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

abstract class AskService {
  Future<Result<SceneAnswer>> ask({
    required SceneContext context,
    required String question,
  });
}
