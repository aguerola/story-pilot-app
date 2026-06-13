import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';

class AskBloc extends Bloc<AskEvent, AskState> {
  AskBloc(
    this._repository,
    this._authService,
    this._usageLimitService,
  ) : super(const AskInitial()) {
    on<AskStarted>(_onStarted);
    on<AskContextUpdated>(_onContextUpdated);
    on<AskQuestionSubmitted>(_onQuestionSubmitted);
  }

  final AskRepository _repository;
  final AuthService _authService;
  final UsageLimitService _usageLimitService;
  SceneContext? _context;

  void _onStarted(AskStarted event, Emitter<AskState> emit) {
    _updateContext(event.context, emit);
  }

  void _onContextUpdated(AskContextUpdated event, Emitter<AskState> emit) {
    _updateContext(event.context, emit);
  }

  void _updateContext(SceneContext context, Emitter<AskState> emit) {
    _context = context;
    emit(const AskInitial());
  }

  Future<void> _onQuestionSubmitted(
    AskQuestionSubmitted event,
    Emitter<AskState> emit,
  ) async {
    final context = _context;
    if (context == null) {
      emit(const AskMissingContext());
      return;
    }
    if (event.question.trim().isEmpty) return;

    if (_authService.currentUser == null &&
        !_usageLimitService.canAskAnonymously()) {
      emit(const AskAuthRequired());
      return;
    }

    if (_authService.currentUser == null) {
      _usageLimitService.recordAnonymousQuestion();
    }

    emit(AskAnswering(event.question));
    final result = await _repository.ask(
      context: context,
      question: event.question.trim(),
      model: GeminiModel.defaultModel,
    );
    switch (result) {
      case Success(:final data):
        emit(AskAnswered(data));
      case Error(:final failure):
        emit(AskFailure(failure));
    }
  }
}
