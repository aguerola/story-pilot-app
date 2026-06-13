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

  test('ask dialogue includes subtitles from start through timestamp plus window',
      () {
    final document = SubtitleDocument(
      titleId: 1,
      language: 'es',
      fileId: '1',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 10000, text: 'Inicio'),
        SubtitleLine(startMs: 50000, endMs: 55000, text: 'Mitad'),
        SubtitleLine(startMs: 95000, endMs: 100000, text: 'Después'),
      ],
    );

    final context = analyzer.buildContext(
      subtitles: document,
      cast: const [],
      timestampMs: 60000,
    );

    expect(context.dialogueText, 'Inicio\nMitad');
    expect(context.askDialogueText, 'Inicio\nMitad');
    expect(context.priorDialogueText, isEmpty);
    expect(context.askDialogueText, isNot(contains('Después')));
  });

  test('scene window spans two minutes before and thirty seconds after', () {
    final document = SubtitleDocument(
      titleId: 1,
      language: 'es',
      fileId: '1',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 10000, text: 'Inicio'),
        SubtitleLine(startMs: 30000, endMs: 35000, text: 'Antes'),
        SubtitleLine(startMs: 50000, endMs: 55000, text: 'Mitad'),
        SubtitleLine(startMs: 95000, endMs: 100000, text: 'Después'),
      ],
    );

    final context = analyzer.buildContext(
      subtitles: document,
      cast: const [],
      timestampMs: 60000,
    );

    expect(context.dialogueText, 'Inicio\nAntes\nMitad');
    expect(context.sceneBeforeSeconds, 120);
    expect(context.sceneAfterSeconds, 30);
  });
}
