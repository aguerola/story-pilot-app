import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/data/services/scene_analyzer_service.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';

void main() {
  final analyzer = SceneAnalyzerService();

  test('detects characters mentioned in dialogue', () {
    final document = SubtitleDocument(
      titleId: 1,
      language: 'es',
      fileId: '1',
      lines: const [
        SubtitleLine(
          startMs: 0,
          endMs: 10000,
          text: 'Neo habla con Morpheus sobre la Matrix',
        ),
      ],
    );

    const cast = [
      CastMember(
        id: 1,
        name: 'Keanu Reeves',
        characterName: 'Neo',
        billingOrder: 0,
      ),
      CastMember(
        id: 2,
        name: 'Laurence Fishburne',
        characterName: 'Morpheus',
        billingOrder: 1,
      ),
    ];

    final context = analyzer.buildContext(
      subtitles: document,
      cast: cast,
      timestampMs: 5000,
    );

    expect(context.activeLine?.text, contains('Neo'));
    expect(context.characters, hasLength(2));
    expect(context.characters.first.confidence, MatchConfidence.high);
  });
}
