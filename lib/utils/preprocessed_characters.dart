import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/utils/brief_characters.dart';

List<SceneCharacter> resolvePreprocessedCharacters(
  List<String> names,
  List<CastMember> cast,
) {
  final resolved = resolveBriefCharacters(names, cast);
  return resolved
      .map(
        (character) => SceneCharacter(
          castMember: character.castMember,
          confidence: character.confidence,
          matchedBy: 'Preprocesado',
        ),
      )
      .toList();
}
