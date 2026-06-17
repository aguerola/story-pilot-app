import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/scene_breakdown.dart';
import 'package:storypilot/utils/scene_breakdown_resolver.dart';
import 'package:storypilot/utils/scene_progress_mapper.dart';

/// YouTube-style segmented progress bar where each segment maps to a [SceneSegment].
class SceneSegmentedProgressBar extends StatefulWidget {
  const SceneSegmentedProgressBar({
    super.key,
    required this.scenes,
    required this.totalDurationMs,
    required this.valueMs,
    this.onChanged,
    this.onChangeEnd,
    this.height = 4,
    this.segmentGap = 3,
    this.thumbRadius = 6,
  });

  final List<SceneSegment> scenes;
  final int totalDurationMs;
  final double valueMs;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double height;
  final double segmentGap;
  final double thumbRadius;

  @override
  State<SceneSegmentedProgressBar> createState() =>
      _SceneSegmentedProgressBarState();
}

class _SceneSegmentedProgressBarState extends State<SceneSegmentedProgressBar> {
  double? _draggingValue;

  double get _displayValue => _draggingValue ?? widget.valueMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = widget.onChanged != null;
    final clampedValue = _displayValue
        .clamp(0, widget.totalDurationMs.toDouble())
        .toDouble();
    final activeIndex = widget.scenes.isEmpty
        ? -1
        : findActiveSceneIndex(widget.scenes, clampedValue.toInt());

    return SizedBox(
      height: widget.thumbRadius * 2 + 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final thumbX = widget.scenes.isEmpty
              ? linearMsToX(
                  clampedValue,
                  barWidth,
                  widget.totalDurationMs,
                )
              : segmentedMsToX(
                  clampedValue,
                  barWidth,
                  widget.scenes,
                  widget.totalDurationMs,
                  widget.segmentGap,
                );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: enabled ? (_) => _startDrag() : null,
            onHorizontalDragUpdate: enabled
                ? (details) => _seekFromLocalX(details.localPosition.dx, barWidth)
                : null,
            onHorizontalDragEnd: enabled ? (_) => _endDrag() : null,
            onTapDown: enabled
                ? (details) {
                    _startDrag();
                    _seekFromLocalX(details.localPosition.dx, barWidth);
                  }
                : null,
            onTapUp: enabled ? (_) => _endDrag() : null,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                if (widget.scenes.isEmpty)
                  _ContinuousBar(
                    width: barWidth,
                    height: widget.height,
                    progress: widget.totalDurationMs > 0
                        ? clampedValue / widget.totalDurationMs
                        : 0,
                    trackColor: colorScheme.surfaceContainerHighest,
                    progressColor: colorScheme.primary,
                  )
                else
                  _SegmentedBar(
                    width: barWidth,
                    height: widget.height,
                    gap: widget.segmentGap,
                    scenes: widget.scenes,
                    totalDurationMs: widget.totalDurationMs,
                    valueMs: clampedValue,
                    activeIndex: activeIndex,
                    trackColor: colorScheme.surfaceContainerHighest,
                    progressColor: colorScheme.primary,
                    activeTrackColor:
                        colorScheme.primary.withValues(alpha: 0.35),
                  ),
                Positioned(
                  left: (thumbX - widget.thumbRadius)
                      .clamp(0, barWidth - widget.thumbRadius * 2),
                  child: Container(
                    width: widget.thumbRadius * 2,
                    height: widget.thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.25),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startDrag() {
    setState(() => _draggingValue = widget.valueMs);
  }

  void _endDrag() {
    final value = _draggingValue ?? widget.valueMs;
    setState(() => _draggingValue = null);
    widget.onChangeEnd?.call(value);
  }

  void _seekFromLocalX(double localX, double barWidth) {
    if (widget.onChanged == null || widget.totalDurationMs <= 0) return;
    final ms = widget.scenes.isEmpty
        ? linearXToMs(localX, barWidth, widget.totalDurationMs)
        : segmentedXToMs(
            localX,
            barWidth,
            widget.scenes,
            widget.totalDurationMs,
            widget.segmentGap,
          );
    final clamped = ms.clamp(0, widget.totalDurationMs.toDouble()).toDouble();
    setState(() => _draggingValue = clamped);
    widget.onChanged!(clamped);
  }
}

class _ContinuousBar extends StatelessWidget {
  const _ContinuousBar({
    required this.width,
    required this.height,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double width;
  final double height;
  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Container(width: width, height: height, color: trackColor),
            Container(
              width: width * progress.clamp(0, 1),
              height: height,
              color: progressColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({
    required this.width,
    required this.height,
    required this.gap,
    required this.scenes,
    required this.totalDurationMs,
    required this.valueMs,
    required this.activeIndex,
    required this.trackColor,
    required this.progressColor,
    required this.activeTrackColor,
  });

  final double width;
  final double height;
  final double gap;
  final List<SceneSegment> scenes;
  final int totalDurationMs;
  final double valueMs;
  final int activeIndex;
  final Color trackColor;
  final Color progressColor;
  final Color activeTrackColor;

  @override
  Widget build(BuildContext context) {
    final segmentsWidth =
        width - gap * (scenes.length - 1).clamp(0, scenes.length);

    return Row(
      children: [
        for (var i = 0; i < scenes.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          _Segment(
            width: sceneSegmentWidth(scenes[i], segmentsWidth, totalDurationMs),
            height: height,
            fill: sceneSegmentFill(scenes[i], valueMs),
            isActive: i == activeIndex,
            trackColor: trackColor,
            progressColor: progressColor,
            activeTrackColor: activeTrackColor,
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.width,
    required this.height,
    required this.fill,
    required this.isActive,
    required this.trackColor,
    required this.progressColor,
    required this.activeTrackColor,
  });

  final double width;
  final double height;
  final double fill;
  final bool isActive;
  final Color trackColor;
  final Color progressColor;
  final Color activeTrackColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Container(
              width: width,
              height: height,
              color: isActive ? activeTrackColor : trackColor,
            ),
            Container(
              width: width * fill.clamp(0, 1),
              height: height,
              color: progressColor,
            ),
          ],
        ),
      ),
    );
  }
}
