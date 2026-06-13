import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/utils/text_utils.dart';

class SceneAnalyzerService {
  SceneContext buildContext({
    required SubtitleDocument subtitles,
    required List<CastMember> cast,
    required int timestampMs,
    int windowSeconds = 30,
  }) {
    final windowLines = linesInWindow(
      subtitles.lines,
      timestampMs,
      windowSeconds,
    );
    final dialogueText = aggregateDialogue(windowLines);
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
      windowSeconds: windowSeconds,
      activeLine: activeLine,
      dialogueText: dialogueText,
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
