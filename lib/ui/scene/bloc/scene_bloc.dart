import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> {
  SceneBloc(this._repository, this._subtitleRepository, this._session)
      : super(const SceneInitial()) {
    on<SceneStarted>(_onStarted);
    on<TimestampChanged>(_onTimestampChanged);
  }

  final SceneRepository _repository;
  final SubtitleRepository _subtitleRepository;
  final TitleSessionHolder _session;

  Future<void> _onStarted(
    SceneStarted event,
    Emitter<SceneState> emit,
  ) async {
    final subtitles = await _resolveSubtitles(event.tmdbId, emit);
    if (subtitles == null) {
      return;
    }
    await _loadContext(event.initialTimestampMs, emit);
  }

  Future<SubtitleDocument?> _resolveSubtitles(
    int tmdbId,
    Emitter<SceneState> emit,
  ) async {
    final sessionDoc = _session.subtitleDocument;
    if (sessionDoc != null && sessionDoc.titleId == tmdbId) {
      return sessionDoc;
    }

    final cached = await _subtitleRepository.getCachedForTitle(tmdbId);
    if (cached != null && cached.language == SubtitleRepository.subtitleLanguage) {
      _session.setSubtitleDocument(cached);
      return cached;
    }

    emit(const SceneLoading());
    final mediaType =
        _session.titleDetail?.summary.mediaType ?? MediaType.movie;
    final result = await _subtitleRepository.ensureSubtitleForTitle(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );
    switch (result) {
      case Success(:final data):
        _session.setSubtitleDocument(data);
        return data;
      case Error(:final failure):
        emit(SceneFailure(failure));
        return null;
    }
  }

  Future<void> _onTimestampChanged(
    TimestampChanged event,
    Emitter<SceneState> emit,
  ) async {
    await _loadContext(event.timestampMs, emit);
  }

  Future<void> _loadContext(int timestampMs, Emitter<SceneState> emit) async {
    final subtitles = _session.subtitleDocument;
    if (subtitles == null) {
      emit(const SceneFailure(NotFoundFailure('Subtitles not available')));
      return;
    }
    emit(const SceneLoading());
    final result = await _repository.getContext(
      subtitles: subtitles,
      cast: _session.cast,
      timestampMs: timestampMs,
      titleLabel: _session.titleDetail?.summary.displayLabel,
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
