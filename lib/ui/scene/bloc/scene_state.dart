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

final class SceneMissingData extends SceneState {
  const SceneMissingData();
}
