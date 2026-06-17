import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/domain/models/scene_breakdown.dart';
import 'package:storypilot/utils/scene_progress_mapper.dart';

void main() {
  const scenes = [
    SceneSegment(
      startMs: 0,
      endMs: 30_000,
      summary: 'Opening',
      detailedSummary: 'Scene one.',
      characters: ['Neo'],
    ),
    SceneSegment(
      startMs: 30_000,
      endMs: 90_000,
      summary: 'Conflict',
      detailedSummary: 'Scene two.',
      characters: ['Neo', 'Trinity'],
    ),
    SceneSegment(
      startMs: 90_000,
      endMs: 150_000,
      summary: 'Climax',
      detailedSummary: 'Scene three.',
      characters: ['Neo'],
    ),
  ];

  const totalDurationMs = 150_000;
  const barWidth = 300.0;
  const gap = 3.0;

  test('segmentedMsToX and segmentedXToMs are inverse at scene midpoints', () {
    for (final scene in scenes) {
      final midpoint = (scene.startMs + scene.endMs) / 2.0;
      final x = segmentedMsToX(
        midpoint,
        barWidth,
        scenes,
        totalDurationMs,
        gap,
      );
      final ms = segmentedXToMs(x, barWidth, scenes, totalDurationMs, gap);
      expect(ms, closeTo(midpoint, 1));
    }
  });

  test('sceneSegmentFill reflects progress within a segment', () {
    expect(sceneSegmentFill(scenes[1], 30_000), 0);
    expect(sceneSegmentFill(scenes[1], 60_000), closeTo(0.5, 0.001));
    expect(sceneSegmentFill(scenes[1], 90_000), 1);
  });

  test('linear mapping covers full bar width', () {
    expect(linearMsToX(0, barWidth, totalDurationMs), 0);
    expect(linearMsToX(totalDurationMs.toDouble(), barWidth, totalDurationMs),
        barWidth);
    expect(linearXToMs(barWidth, barWidth, totalDurationMs), totalDurationMs);
  });
}
