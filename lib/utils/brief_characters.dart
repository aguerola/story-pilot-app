import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/utils/text_utils.dart';

/// Maps AI-returned character names back to TMDB cast members for display.
List<SceneCharacter> resolveBriefCharacters(
  List<String> names,
  List<CastMember> cast,
) {
  final byName = <String, CastMember>{};
  for (final member in cast) {
    byName.putIfAbsent(normalizeText(member.characterName), () => member);
  }
  final seen = <int>{};
  final characters = <SceneCharacter>[];
  for (final name in names) {
    final member = byName[normalizeText(name)];
    if (member == null || !seen.add(member.id)) continue;
    characters.add(
      SceneCharacter(
        castMember: member,
        confidence: MatchConfidence.high,
        matchedBy: 'Detectado por IA',
      ),
    );
  }
  return characters;
}
