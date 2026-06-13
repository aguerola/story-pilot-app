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
    required this.windowSeconds,
    this.activeLine,
    required this.dialogueText,
    required this.characters,
  });

  final int timestampMs;
  final int windowSeconds;
  final SubtitleLine? activeLine;
  final String dialogueText;
  final List<SceneCharacter> characters;

  @override
  List<Object?> get props =>
      [timestampMs, windowSeconds, activeLine, dialogueText, characters];
}
