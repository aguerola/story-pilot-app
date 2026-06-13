import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/utils/text_utils.dart';

class SceneAnalyzerService {
  static const sceneBeforeSeconds = 120;
  static const sceneAfterSeconds = 30;

  SceneContext buildContext({
    required SubtitleDocument subtitles,
    required List<CastMember> cast,
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
    final normalizedDialogue = normalizeText(dialogueText);
    SubtitleLine? activeLine;
    for (final line in subtitles.lines) {
      if (line.containsTimestamp(timestampMs)) {
        activeLine = line;
        break;
      }
    }

    final characters = <SceneCharacter>[];
    for (final member in cast) {
      final match = _matchCharacter(member, normalizedDialogue, dialogueText);
      if (match != null) {
        characters.add(match);
      }
    }

    characters.sort(
      (a, b) =>
          a.castMember.billingOrder.compareTo(b.castMember.billingOrder),
    );

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
      characters: characters,
    );
  }

  SceneCharacter? _matchCharacter(
    CastMember member,
    String normalizedDialogue,
    String rawDialogue,
  ) {
    final character = normalizeText(member.characterName);
    final actor = normalizeText(member.name);
    final actorLastName = actor.split(' ').last;

    if (character.isNotEmpty && containsWord(normalizedDialogue, character)) {
      return SceneCharacter(
        castMember: member,
        confidence: MatchConfidence.high,
        matchedBy: 'Nombre de personaje en subtítulo',
      );
    }

    if (actor.isNotEmpty && containsWord(normalizedDialogue, actor)) {
      return SceneCharacter(
        castMember: member,
        confidence: MatchConfidence.high,
        matchedBy: 'Nombre de actor en subtítulo',
      );
    }

    if (actorLastName.length > 2 &&
        containsWord(normalizedDialogue, actorLastName)) {
      return SceneCharacter(
        castMember: member,
        confidence: MatchConfidence.medium,
        matchedBy: 'Apellido en subtítulo',
      );
    }

    final dialoguePattern = RegExp(
      r'[-\[]\s*' + RegExp.escape(member.characterName.split(' ').first),
      caseSensitive: false,
    );
    if (dialoguePattern.hasMatch(rawDialogue)) {
      return SceneCharacter(
        castMember: member,
        confidence: MatchConfidence.low,
        matchedBy: 'Formato de diálogo',
      );
    }

    return null;
  }
}
