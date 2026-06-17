import 'package:storypilot/domain/models/scene_breakdown.dart';

int findActiveSceneIndex(List<SceneSegment> scenes, int timestampMs) {
  final direct = scenes.indexWhere(
    (scene) => timestampMs >= scene.startMs && timestampMs <= scene.endMs,
  );
  if (direct >= 0) {
    return direct;
  }

  var fallback = -1;
  for (var index = 0; index < scenes.length; index++) {
    if (scenes[index].startMs <= timestampMs) {
      fallback = index;
    }
  }
  return fallback;
}

SceneSegment? resolveSceneAtTimestamp(
  List<SceneSegment> scenes,
  int timestampMs,
) {
  final activeIndex = findActiveSceneIndex(scenes, timestampMs);
  if (activeIndex < 0) {
    return null;
  }
  return scenes[activeIndex];
}
