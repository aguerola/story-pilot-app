import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_context.dart';

sealed class SceneState extends Equatable {
  const SceneState();

  @override
  List<Object?> get props => [];
}

final class SceneInitial extends SceneState {
  const SceneInitial();
}

final class SceneLoading extends SceneState {
  const SceneLoading();
}

/// Subtitles are ready but no scene is loaded yet: we wait for the user to
/// enter the moment they're watching instead of defaulting to 00:00:00.
final class SceneAwaitingTimestamp extends SceneState {
  const SceneAwaitingTimestamp();
}

final class SceneLoaded extends SceneState {
  const SceneLoaded(this.context);

  final SceneContext context;

  @override
  List<Object?> get props => [context];
}

final class SceneFailure extends SceneState {
  const SceneFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
