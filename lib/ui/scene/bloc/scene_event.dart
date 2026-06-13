import 'package:equatable/equatable.dart';

sealed class SceneEvent extends Equatable {
  const SceneEvent();

  @override
  List<Object?> get props => [];
}

final class SceneStarted extends SceneEvent {
  const SceneStarted({this.initialTimestampMs = 0});

  final int initialTimestampMs;

  @override
  List<Object?> get props => [initialTimestampMs];
}

final class TimestampChanged extends SceneEvent {
  const TimestampChanged(this.timestampMs);

  final int timestampMs;

  @override
  List<Object?> get props => [timestampMs];
}

final class WindowSecondsChanged extends SceneEvent {
  const WindowSecondsChanged(this.windowSeconds);

  final int windowSeconds;

  @override
  List<Object?> get props => [windowSeconds];
}
