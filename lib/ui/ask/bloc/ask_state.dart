import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/scene_answer.dart';

sealed class AskState extends Equatable {
  const AskState();

  @override
  List<Object?> get props => [];
}

final class AskInitial extends AskState {
  const AskInitial();
}

final class AskAnswering extends AskState {
  const AskAnswering(this.question);

  final String question;

  @override
  List<Object?> get props => [question];
}

final class AskAnswered extends AskState {
  const AskAnswered(this.answer);

  final SceneAnswer answer;

  @override
  List<Object?> get props => [answer];
}

final class AskFailure extends AskState {
  const AskFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class AskMissingContext extends AskState {
  const AskMissingContext();
}
