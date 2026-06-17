import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/ui/core/ui/person_detail_sheet.dart';

class CharacterChip extends StatelessWidget {
  const CharacterChip({
    super.key,
    required this.character,
    this.onTap,
  });

  static const _avatarSize = 48.0;

  final SceneCharacter character;
  final VoidCallback? onTap;

  Color _confidenceColor(MatchConfidence confidence) {
    return switch (confidence) {
      MatchConfidence.high => Colors.green.shade600,
      MatchConfidence.medium => Colors.orange.shade600,
      MatchConfidence.low => Colors.grey.shade500,
    };
  }

  String get _fallbackInitial {
    final name = character.castMember.characterName.isNotEmpty
        ? character.castMember.characterName
        : character.castMember.name;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final profileUrl = character.castMember.profileUrl;
    final confidenceColor = _confidenceColor(character.confidence);

    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: confidenceColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: profileUrl != null
            ? Image.network(
                profileUrl,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallback(theme),
              )
            : _buildFallback(theme),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          _fallbackInitial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handleTap = onTap ??
        () => showPersonDetailSheet(
              context,
              castMember: character.castMember,
            );

    return Tooltip(
      message: '${character.confidence.label}: ${character.matchedBy}',
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 10),
                Text(
                  character.castMember.characterName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
