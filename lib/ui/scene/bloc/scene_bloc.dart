import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> {
  SceneBloc(this._repository, this._session) : super(const SceneInitial()) {
    on<SceneStarted>(_onStarted);
    on<TimestampChanged>(_onTimestampChanged);
    on<WindowSecondsChanged>(_onWindowChanged);
  }

  final SceneRepository _repository;
  final TitleSessionHolder _session;
  var _windowSeconds = 30;

  Future<void> _onStarted(
    SceneStarted event,
    Emitter<SceneState> emit,
  ) async {
    if (_session.subtitleDocument == null) {
      emit(const SceneMissingData());
      return;
    }
    await _loadContext(event.initialTimestampMs, emit);
  }

  Future<void> _onTimestampChanged(
    TimestampChanged event,
    Emitter<SceneState> emit,
  ) async {
    await _loadContext(event.timestampMs, emit);
  }

  Future<void> _onWindowChanged(
    WindowSecondsChanged event,
    Emitter<SceneState> emit,
  ) async {
    _windowSeconds = event.windowSeconds;
    final current = state;
    if (current is SceneLoaded) {
      await _loadContext(current.context.timestampMs, emit);
    }
  }

  Future<void> _loadContext(int timestampMs, Emitter<SceneState> emit) async {
    final subtitles = _session.subtitleDocument;
    if (subtitles == null) {
      emit(const SceneMissingData());
      return;
    }
    emit(const SceneLoading());
    final result = await _repository.getContext(
      subtitles: subtitles,
      cast: _session.cast,
      timestampMs: timestampMs,
      windowSeconds: _windowSeconds,
    );
    switch (result) {
      case Success(:final data):
        _session.setSceneContext(data);
        emit(SceneLoaded(data));
      case Error(:final failure):
        emit(SceneFailure(failure));
    }
  }
}
