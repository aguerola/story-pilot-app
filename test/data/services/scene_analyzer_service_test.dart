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
    expect(context.priorDialogueText, 'Inicio\nMitad');
    expect(context.askDialogueText, isNot(contains('Después')));
  });

  test('prior dialogue includes all subtitles from start through timestamp', () {
    final document = SubtitleDocument(
      titleId: 1,
      language: 'es',
      fileId: '1',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 10000, text: 'Inicio'),
        SubtitleLine(startMs: 50000, endMs: 55000, text: 'Mitad'),
        SubtitleLine(startMs: 140000, endMs: 145000, text: 'Cerca del momento'),
        SubtitleLine(startMs: 200000, endMs: 205000, text: 'Después'),
      ],
    );

    final context = analyzer.buildContext(
      subtitles: document,
      cast: const [],
      timestampMs: 150000,
    );

    expect(context.priorDialogueText, 'Inicio\nMitad\nCerca del momento');
    expect(context.priorDialogueText, isNot(contains('Después')));
    expect(context.dialogueText, contains('Cerca del momento'));
  });

  test('following dialogue includes only subtitles after timestamp within window',
      () {
    final document = SubtitleDocument(
      titleId: 1,
      language: 'es',
      fileId: '1',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 10000, text: 'Inicio'),
        SubtitleLine(startMs: 50000, endMs: 55000, text: 'Mitad'),
        SubtitleLine(startMs: 62000, endMs: 65000, text: 'Justo después'),
        SubtitleLine(startMs: 95000, endMs: 100000, text: 'Fuera de ventana'),
      ],
    );

    final context = analyzer.buildContext(
      subtitles: document,
      cast: const [],
      timestampMs: 60000,
    );

    expect(context.followingDialogueText, 'Justo después');
    expect(context.priorDialogueText, 'Inicio\nMitad');
    expect(context.dialogueText, contains('Justo después'));
    expect(context.dialogueText, isNot(contains('Fuera de ventana')));
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
    expect(context.priorDialogueText, 'Inicio\nAntes\nMitad');
    expect(context.sceneBeforeSeconds, 120);
    expect(context.sceneAfterSeconds, 30);
  });
}
