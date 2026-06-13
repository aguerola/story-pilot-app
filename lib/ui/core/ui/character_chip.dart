import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';

class CharacterChip extends StatelessWidget {
  const CharacterChip({super.key, required this.character});

  final SceneCharacter character;

  Color _confidenceColor(MatchConfidence confidence, BuildContext context) {
    return switch (confidence) {
      MatchConfidence.high => Colors.green.shade700,
      MatchConfidence.medium => Colors.orange.shade700,
      MatchConfidence.low => Colors.grey.shade600,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${character.confidence.label}: ${character.matchedBy}',
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: _confidenceColor(character.confidence, context),
          child: Text(
            character.confidence.label[0],
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        label: Text(character.castMember.characterName),
      ),
    );
  }
}
