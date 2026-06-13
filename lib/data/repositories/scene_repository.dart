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
    int windowSeconds = 30,
  }) async {
    final context = _analyzer.buildContext(
      subtitles: subtitles,
      cast: cast,
      timestampMs: timestampMs,
      windowSeconds: windowSeconds,
    );
    return Success(context);
  }
}
