import 'package:equatable/equatable.dart';

class SceneAnswer extends Equatable {
  const SceneAnswer({
    required this.question,
    required this.answer,
    this.sources = const [],
  });

  final String question;
  final String answer;
  final List<String> sources;

  @override
  List<Object?> get props => [question, answer, sources];
}
