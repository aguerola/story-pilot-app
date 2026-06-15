import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> {
  SceneBloc(this._repository, this._subtitleRepository, this._session)
      : super(const SceneInitial()) {
    on<SceneStarted>(_onStarted);
    on<EpisodeSelected>(_onEpisodeSelected);
    on<TimestampChanged>(_onTimestampChanged);
  }

  final SceneRepository _repository;
  final SubtitleRepository _subtitleRepository;
  final TitleSessionHolder _session;

  Future<void> _onStarted(
    SceneStarted event,
    Emitter<SceneState> emit,
  ) async {
    final mediaType =
        _session.titleDetail?.summary.mediaType ?? MediaType.movie;
    final episode = _episodeSelection(event, mediaType);
    if (mediaType == MediaType.tv && episode == null) {
      emit(const SceneAwaitingEpisode());
      return;
    }
    if (episode != null) {
      _session.setSelectedEpisode(episode);
    }
    await _loadSubtitlesAndContext(
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
    await _loadSubtitlesAndContext(
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

  Future<void> _loadSubtitlesAndContext({
    required int tmdbId,
    required MediaType mediaType,
    required TvEpisodeSelection? episode,
    required int timestampMs,
    required Emitter<SceneState> emit,
  }) async {
    final subtitles = await _resolveSubtitles(
      tmdbId: tmdbId,
      mediaType: mediaType,
      episode: episode,
      emit: emit,
    );
    if (subtitles == null) {
      return;
    }
    if (timestampMs > 0) {
      await _loadContext(timestampMs, emit);
    } else {
      emit(const SceneAwaitingTimestamp());
    }
  }

  Future<SubtitleDocument?> _resolveSubtitles({
    required int tmdbId,
    required MediaType mediaType,
    required TvEpisodeSelection? episode,
    required Emitter<SceneState> emit,
  }) async {
    final sessionDoc = _session.subtitleDocument;
    if (sessionDoc != null &&
        sessionDoc.titleId == tmdbId &&
        (mediaType != MediaType.tv ||
            _session.selectedEpisode == episode)) {
      return sessionDoc;
    }

    final cached = await _subtitleRepository.getCachedForTitle(
      tmdbId,
      episode: episode,
    );
    if (cached != null && cached.language == SubtitleRepository.subtitleLanguage) {
      _session.setSubtitleDocument(cached);
      return cached;
    }

    emit(const SceneLoading());
    final result = await _subtitleRepository.ensureSubtitleForTitle(
      tmdbId: tmdbId,
      mediaType: mediaType,
      episode: episode,
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

  Future<void> _loadContext(int timestampMs, Emitter<SceneState> emit) async {
    final subtitles = _session.subtitleDocument;
    if (subtitles == null) {
      emit(const SceneFailure(NotFoundFailure('Subtitles not available')));
      return;
    }
    emit(const SceneLoading());
    final result = await _repository.getContext(
      subtitles: subtitles,
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
