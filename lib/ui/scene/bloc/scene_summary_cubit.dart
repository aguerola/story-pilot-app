import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';

/// Generates the "what's happening" summary shown automatically when a scene
/// loads. It is free for the user: it never consumes the daily question quota
/// and always uses the cheap Lite model.
class SceneSummaryCubit extends Cubit<SceneSummaryState> {
  SceneSummaryCubit(this._repository) : super(const SceneSummaryInitial());

  static const _prompt =
      'Resume en 2-3 frases qué está ocurriendo en esta escena y quién '
      'participa, en lenguaje natural. No reveles nada que pase después del '
      'momento seleccionado (sin spoilers).';

  final AskRepository _repository;

  Future<void> summarize(SceneContext context) async {
    emit(const SceneSummaryLoading());
    final result = await _repository.ask(
      context: context,
      question: _prompt,
      model: GeminiModel.flashLite25,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(SceneSummaryReady(data.answer));
      case Error(:final failure):
        emit(SceneSummaryFailure(failure.message));
    }
  }
}

sealed class SceneSummaryState extends Equatable {
  const SceneSummaryState();

  @override
  List<Object?> get props => [];
}

final class SceneSummaryInitial extends SceneSummaryState {
  const SceneSummaryInitial();
}

final class SceneSummaryLoading extends SceneSummaryState {
  const SceneSummaryLoading();
}

final class SceneSummaryReady extends SceneSummaryState {
  const SceneSummaryReady(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class SceneSummaryFailure extends SceneSummaryState {
  const SceneSummaryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
