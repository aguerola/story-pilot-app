import 'package:storypilot/domain/models/scene_breakdown.dart';

double sceneSegmentWidth(
  SceneSegment scene,
  double segmentsWidth,
  int totalDurationMs,
) {
  if (totalDurationMs <= 0) return 0;
  final duration = (scene.endMs - scene.startMs).clamp(0, totalDurationMs);
  return segmentsWidth * duration / totalDurationMs;
}

double sceneSegmentFill(SceneSegment scene, double valueMs) {
  final duration = scene.endMs - scene.startMs;
  if (duration <= 0) return 0;
  if (valueMs <= scene.startMs) return 0;
  if (valueMs >= scene.endMs) return 1;
  return (valueMs - scene.startMs) / duration;
}

double linearMsToX(double ms, double width, int totalDurationMs) {
  if (totalDurationMs <= 0) return 0;
  return width * ms / totalDurationMs;
}

double linearXToMs(double x, double width, int totalDurationMs) {
  if (width <= 0) return 0;
  return totalDurationMs * x.clamp(0, width) / width;
}

double segmentedMsToX(
  double ms,
  double width,
  List<SceneSegment> scenes,
  int totalDurationMs,
  double gap,
) {
  if (totalDurationMs <= 0 || scenes.isEmpty) return 0;
  final segmentsWidth = width - gap * (scenes.length - 1);
  var x = 0.0;

  for (var i = 0; i < scenes.length; i++) {
    final scene = scenes[i];
    final segmentWidth = sceneSegmentWidth(scene, segmentsWidth, totalDurationMs);
    final duration = scene.endMs - scene.startMs;

    if (ms <= scene.endMs) {
      final localMs = ms.clamp(scene.startMs.toDouble(), scene.endMs.toDouble());
      final fraction = duration > 0 ? (localMs - scene.startMs) / duration : 0;
      return x + segmentWidth * fraction;
    }

    x += segmentWidth;
    if (i < scenes.length - 1) {
      x += gap;
    }
  }

  return width;
}

double segmentedXToMs(
  double x,
  double width,
  List<SceneSegment> scenes,
  int totalDurationMs,
  double gap,
) {
  if (width <= 0 || totalDurationMs <= 0 || scenes.isEmpty) return 0;

  final clampedX = x.clamp(0, width);
  final segmentsWidth = width - gap * (scenes.length - 1);
  var cursor = 0.0;

  for (var i = 0; i < scenes.length; i++) {
    final scene = scenes[i];
    final segmentWidth = sceneSegmentWidth(scene, segmentsWidth, totalDurationMs);
    final duration = scene.endMs - scene.startMs;

    if (clampedX <= cursor + segmentWidth) {
      final fraction =
          segmentWidth > 0 ? (clampedX - cursor) / segmentWidth : 0;
      return scene.startMs + duration * fraction.toDouble();
    }

    cursor += segmentWidth;
    if (i < scenes.length - 1) {
      if (clampedX <= cursor + gap) {
        final gapFraction = gap > 0 ? (clampedX - cursor) / gap : 0;
        final nextScene = scenes[i + 1];
        return (scene.endMs + (nextScene.startMs - scene.endMs) * gapFraction)
            .toDouble();
      }
      cursor += gap;
    }
  }

  return totalDurationMs.toDouble();
}
