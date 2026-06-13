import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';

class SceneCharacter extends Equatable {
  const SceneCharacter({
    required this.castMember,
    required this.confidence,
    required this.matchedBy,
  });

  final CastMember castMember;
  final MatchConfidence confidence;
  final String matchedBy;

  @override
  List<Object?> get props => [castMember, confidence, matchedBy];
}

class SceneContext extends Equatable {
  const SceneContext({
    required this.timestampMs,
    required this.sceneBeforeSeconds,
    required this.sceneAfterSeconds,
    this.activeLine,
    required this.dialogueText,
    required this.askDialogueText,
    required this.priorDialogueText,
    this.followingDialogueText = '',
    this.titleLabel,
    required this.characters,
  });

  final int timestampMs;
  final int sceneBeforeSeconds;
  final int sceneAfterSeconds;
  final SubtitleLine? activeLine;
  final String dialogueText;
  final String askDialogueText;
  final String priorDialogueText;
  final String followingDialogueText;
  final String? titleLabel;
  final List<SceneCharacter> characters;

  String get sceneWindowLabel =>
      '${sceneBeforeSeconds ~/ 60} min antes → ${sceneAfterSeconds}s después';

  @override
  List<Object?> get props => [
        timestampMs,
        sceneBeforeSeconds,
        sceneAfterSeconds,
        activeLine,
        dialogueText,
        askDialogueText,
        priorDialogueText,
        followingDialogueText,
        titleLabel,
        characters,
      ];
}
