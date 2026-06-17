import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/utils/brief_characters.dart';

void main() {
  const cast = [
    CastMember(
      id: 1,
      name: 'Sam Worthington',
      characterName: 'Jake Sully',
      billingOrder: 0,
    ),
    CastMember(
      id: 2,
      name: 'Zoe Saldaña',
      characterName: 'Neytiri',
      billingOrder: 1,
    ),
  ];

  test('resolveBriefCharacters maps AI names to TMDB cast and drops unknowns', () {
    final characters = resolveBriefCharacters(
      ['Jake Sully', 'Na\'vi', 'Jake Sully'],
      cast,
    );

    expect(characters.length, 1);
    expect(characters.first.castMember.characterName, 'Jake Sully');
    expect(characters.first.confidence, MatchConfidence.high);
    expect(characters.first.matchedBy, 'Detectado por IA');
  });

  test('resolveBriefCharacters returns empty when no names match', () {
    expect(resolveBriefCharacters(['Unknown'], cast), isEmpty);
  });
}
