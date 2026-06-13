import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/domain/models/scene_brief.dart';

void main() {
  test('parses structured JSON from the model', () {
    final json = jsonDecode('''
{
  "summary": "  Jake lidera al grupo.  ",
  "characters": ["Jake Sully", "", "Neytiri"],
  "questions": ["¿Qué pasa?", "¿Por qué?"]
}
''') as Map<String, dynamic>;

    final brief = SceneBrief.fromJson(json);

    expect(brief.summary, 'Jake lidera al grupo.');
    expect(brief.presentCharacterNames, ['Jake Sully', 'Neytiri']);
    expect(brief.questions, ['¿Qué pasa?', '¿Por qué?']);
  });

  test('tolerates missing or malformed fields', () {
    final brief = SceneBrief.fromJson(const {'summary': 'Solo resumen'});

    expect(brief.summary, 'Solo resumen');
    expect(brief.presentCharacterNames, isEmpty);
    expect(brief.questions, isEmpty);
  });
}
