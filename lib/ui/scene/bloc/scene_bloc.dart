import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/brief_cast.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';
import 'package:storypilot/utils/bloc_debounce.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> {
  SceneBloc(this._repository, this._titles, this._session)
      : super(const SceneInitial()) {
    on<SceneStarted>(_onStarted);
    on<EpisodeSelected>(_onEpisodeSelected);
    on<TimestampChanged>(
      _onTimestampChanged,
      transformer: debounce(const Duration(milliseconds: 400)),
    );
  }

  final SceneRepository _repository;
  final TitleRepository _titles;
  final TitleSessionHolder _session;

  Future<void> _onStarted(
    SceneStarted event,
    Emitter<SceneState> emit,
  ) async {
    final mediaType = _resolveMediaType(event);
    final episode = _episodeSelection(event, mediaType);
    if (mediaType == MediaType.tv && episode == null) {
      emit(const SceneAwaitingEpisode());
      return;
    }
    if (episode != null) {
      _session.setSelectedEpisode(episode);
    }
    await _prepareAndMaybeLoadContext(
      tmdbId: event.tmdbId,
      mediaType: mediaType,
      episode: episode,
      timestampMs: event.initialTimestampMs,
      emit: emit,
    );
  }

  Future<void> _onEpisodeSelected(
    EpisodeSelected event,
    Emitter<SceneState> emit,
  ) async {
    final mediaType =
        _session.titleDetail?.summary.mediaType ?? MediaType.tv;
    final episode = TvEpisodeSelection(
      seasonNumber: event.seasonNumber,
      episodeNumber: event.episodeNumber,
    );
    _session.setSelectedEpisode(episode);
    _session.clearPlaybackState();
    await _prepareAndMaybeLoadContext(
      tmdbId: _session.titleDetail?.summary.id ?? 0,
      mediaType: mediaType,
      episode: episode,
      timestampMs: 0,
      emit: emit,
    );
  }

  Future<void> _onTimestampChanged(
    TimestampChanged event,
    Emitter<SceneState> emit,
  ) async {
    await _loadContext(event.timestampMs, emit);
  }

  MediaType _resolveMediaType(SceneStarted event) {
    final detail = _session.titleDetail;
    if (detail != null && detail.summary.id == event.tmdbId) {
      return detail.summary.mediaType;
    }
    return event.mediaType;
  }

  TvEpisodeSelection? _episodeSelection(SceneStarted event, MediaType type) {
    if (type != MediaType.tv) return null;
    if (event.seasonNumber != null && event.episodeNumber != null) {
      return TvEpisodeSelection(
        seasonNumber: event.seasonNumber!,
        episodeNumber: event.episodeNumber!,
      );
    }
    return _session.selectedEpisode;
  }

  Future<void> _prepareAndMaybeLoadContext({
    required int tmdbId,
    required MediaType mediaType,
    required TvEpisodeSelection? episode,
    required int timestampMs,
    required Emitter<SceneState> emit,
  }) async {
    emit(const SceneLoading());

    final detail = _session.titleDetail;
    if (detail == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }

    await _loadSceneCast(detail: detail, episode: episode);

    final prepareResult = await _repository.prepareScene(
      tmdbId: tmdbId,
      mediaType: mediaType,
      episode: episode,
      titleLabel: _session.titleDetail?.summary.displayLabel,
      imdbId: _session.titleDetail?.imdbId,
    );
    switch (prepareResult) {
      case Success(:final data):
        _session.setDurationMs(data);
      case Error(:final failure):
        emit(SceneFailure(failure));
        return;
    }

    if (timestampMs > 0) {
      await _loadContext(timestampMs, emit);
    } else {
      emit(const SceneAwaitingTimestamp());
    }
  }

  Future<void> _loadContext(int timestampMs, Emitter<SceneState> emit) async {
    final detail = _session.titleDetail;
    if (detail == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }

    emit(const SceneLoading());
    final mediaType = detail.summary.mediaType;
    final result = await _repository.getContext(
      tmdbId: detail.summary.id,
      mediaType: mediaType,
      timestampMs: timestampMs,
      episode: mediaType == MediaType.tv ? _session.selectedEpisode : null,
      titleLabel: detail.summary.displayLabel,
      imdbId: detail.imdbId,
    );
    switch (result) {
      case Success(:final data):
        _session.setSceneContext(data);
        emit(SceneLoaded(data));
      case Error(:final failure):
        emit(SceneFailure(failure));
    }
  }

  Future<void> _loadSceneCast({
    required TitleDetail detail,
    required TvEpisodeSelection? episode,
  }) async {
    final result = await _titles.resolveSceneCast(
      detail: detail,
      episode: episode,
    );
    switch (result) {
      case Success(:final data):
        _session.setSceneCast(data);
      case Error():
        _session.setSceneCast(detail.cast.take(maxBriefCast).toList());
    }
  }
}
