import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/domain/models/scene_breakdown.dart';
import 'package:storypilot/utils/scene_breakdown_resolver.dart';

void main() {
  const scenes = [
    SceneSegment(
      startMs: 0,
      endMs: 30_000,
      summary: 'Opening',
      detailedSummary: 'Scene one complete.',
      characters: ['Neo'],
    ),
    SceneSegment(
      startMs: 30_000,
      endMs: 90_000,
      summary: 'Conflict',
      detailedSummary: 'Scene two complete.',
      characters: ['Neo', 'Trinity'],
    ),
    SceneSegment(
      startMs: 90_000,
      endMs: 150_000,
      summary: 'Climax',
      detailedSummary: 'Scene three complete.',
      characters: ['Neo'],
    ),
  ];

  test('findActiveSceneIndex finds the scene that contains the timestamp', () {
    expect(findActiveSceneIndex(scenes, 45_000), 1);
  });

  test('findActiveSceneIndex falls back to the last started scene', () {
    expect(findActiveSceneIndex(scenes, 95_000), 2);
  });

  test('resolveSceneAtTimestamp returns the active segment', () {
    final segment = resolveSceneAtTimestamp(scenes, 45_000);
    expect(segment?.detailedSummary, 'Scene two complete.');
    expect(segment?.characters, ['Neo', 'Trinity']);
  });
}
