import 'package:storypilot/data/services/scene_analyzer_service.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/result.dart';

class SceneRepository {
  SceneRepository(this._analyzer);

  final SceneAnalyzerService _analyzer;

  Future<Result<SceneContext>> getContext({
    required SubtitleDocument subtitles,
    required List<CastMember> cast,
    required int timestampMs,
    int sceneBeforeSeconds = SceneAnalyzerService.sceneBeforeSeconds,
    int sceneAfterSeconds = SceneAnalyzerService.sceneAfterSeconds,
  }) async {
    final context = _analyzer.buildContext(
      subtitles: subtitles,
      cast: cast,
      timestampMs: timestampMs,
      sceneBeforeSeconds: sceneBeforeSeconds,
      sceneAfterSeconds: sceneAfterSeconds,
    );
    return Success(context);
  }
}
