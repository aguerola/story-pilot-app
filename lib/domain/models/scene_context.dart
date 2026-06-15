import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/dialogue_line.dart';

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
  });

  final int timestampMs;
  final int sceneBeforeSeconds;
  final int sceneAfterSeconds;
  final DialogueLine? activeLine;
  final String dialogueText;
  final String askDialogueText;
  final String priorDialogueText;
  final String followingDialogueText;
  final String? titleLabel;

  String get sceneWindowLabel =>
      '${sceneBeforeSeconds ~/ 60} min antes → ${sceneAfterSeconds}s después';

  /// Payload for Cloud Functions AI callables (anti-spoiler: no post-moment dialogue).
  Map<String, dynamic> toAskPayload() {
    final payload = <String, dynamic>{
      'timestampMs': timestampMs,
      'priorDialogueText': priorDialogueText,
    };
    if (titleLabel != null) {
      payload['titleLabel'] = titleLabel;
    }
    final activeText = activeLine?.text.trim();
    if (activeText != null && activeText.isNotEmpty) {
      payload['activeLine'] = {'text': activeText};
    }
    return payload;
  }

  factory SceneContext.fromApiMap(Map<String, dynamic> json) {
    DialogueLine? activeLine;
    final rawActive = json['activeLine'];
    if (rawActive is Map) {
      activeLine = DialogueLine.fromJson(
        Map<String, dynamic>.from(rawActive),
      );
    }

    return SceneContext(
      timestampMs: json['timestampMs'] as int,
      sceneBeforeSeconds: json['sceneBeforeSeconds'] as int? ?? 120,
      sceneAfterSeconds: json['sceneAfterSeconds'] as int? ?? 30,
      activeLine: activeLine,
      dialogueText: json['dialogueText'] as String? ?? '',
      askDialogueText: json['askDialogueText'] as String? ?? '',
      priorDialogueText: json['priorDialogueText'] as String? ?? '',
      followingDialogueText: json['followingDialogueText'] as String? ?? '',
      titleLabel: json['titleLabel'] as String?,
    );
  }

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
      ];
}
