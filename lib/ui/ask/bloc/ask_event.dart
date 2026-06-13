import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/scene_context.dart';

sealed class AskEvent extends Equatable {
  const AskEvent();

  @override
  List<Object?> get props => [];
}

final class AskStarted extends AskEvent {
  const AskStarted(this.context);

  final SceneContext context;

  @override
  List<Object?> get props => [context];
}

final class AskContextUpdated extends AskEvent {
  const AskContextUpdated(this.context);

  final SceneContext context;

  @override
  List<Object?> get props => [context];
}

final class AskQuestionSubmitted extends AskEvent {
  const AskQuestionSubmitted(this.question);

  final String question;

  @override
  List<Object?> get props => [question];
}
