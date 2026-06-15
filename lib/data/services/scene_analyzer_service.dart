import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/utils/text_utils.dart';

class SceneAnalyzerService {
  static const sceneBeforeSeconds = 120;
  static const sceneAfterSeconds = 30;

  SceneContext buildContext({
    required SubtitleDocument subtitles,
    required int timestampMs,
    int sceneBeforeSeconds = SceneAnalyzerService.sceneBeforeSeconds,
    int sceneAfterSeconds = SceneAnalyzerService.sceneAfterSeconds,
    String? titleLabel,
  }) {
    final windowLines = linesInSceneWindow(
      subtitles.lines,
      timestampMs,
      beforeSeconds: sceneBeforeSeconds,
      afterSeconds: sceneAfterSeconds,
    );
    final askLines = linesFromStartThroughWindow(
      subtitles.lines,
      timestampMs,
      sceneAfterSeconds,
    );
    final priorLines = linesFromStartThroughTimestamp(
      subtitles.lines,
      timestampMs,
    );
    final followingLines = linesAfterTimestampWithinWindow(
      subtitles.lines,
      timestampMs,
      afterSeconds: sceneAfterSeconds,
    );
    final dialogueText = aggregateDialogue(windowLines);
    final askDialogueText = aggregateDialogue(askLines);
    final priorDialogueText = aggregateDialogue(priorLines);
    final followingDialogueText = aggregateDialogue(followingLines);

    SubtitleLine? activeLine;
    for (final line in subtitles.lines) {
      if (line.containsTimestamp(timestampMs)) {
        activeLine = line;
        break;
      }
    }

    return SceneContext(
      timestampMs: timestampMs,
      sceneBeforeSeconds: sceneBeforeSeconds,
      sceneAfterSeconds: sceneAfterSeconds,
      activeLine: activeLine,
      dialogueText: dialogueText,
      askDialogueText: askDialogueText,
      priorDialogueText: priorDialogueText,
      followingDialogueText: followingDialogueText,
      titleLabel: titleLabel,
    );
  }
}
