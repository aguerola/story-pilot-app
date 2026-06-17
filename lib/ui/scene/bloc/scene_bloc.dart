import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/brief_cast.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';
import 'package:storypilot/utils/brief_characters.dart';
import 'package:storypilot/utils/bloc_debounce.dart';
import 'package:storypilot/utils/preprocessed_characters.dart';
import 'package:storypilot/utils/scene_breakdown_resolver.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> {
  SceneBloc(
    this._repository,
    this._titles,
    this._session, {
    Duration preprocessingPollInterval = const Duration(seconds: 2),
    Duration preprocessingTimeout = const Duration(minutes: 2),
  })  : _preprocessingPollInterval = preprocessingPollInterval,
        _preprocessingTimeout = preprocessingTimeout,
        super(const SceneInitial()) {
    on<SceneStarted>(_onStarted);
    on<EpisodeSelected>(_onEpisodeSelected);
    on<PreprocessingRetry>(_onPreprocessingRetry);
    on<TimestampScrubbed>(_onTimestampScrubbed);
    on<TimestampChanged>(
      _onTimestampChanged,
      transformer: debounce(const Duration(milliseconds: 400)),
    );
  }

  final SceneRepository _repository;
  final TitleRepository _titles;
  final TitleSessionHolder _session;
  final Duration _preprocessingPollInterval;
  final Duration _preprocessingTimeout;

  _PrepareParams? _lastPrepareParams;
  int _contextRequestId = 0;

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
    await _prepareScene(
      tmdbId: event.tmdbId,
      mediaType: mediaType,
      episode: episode,
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
    await _prepareScene(
      tmdbId: _session.titleDetail?.summary.id ?? 0,
      mediaType: mediaType,
      episode: episode,
      emit: emit,
    );
  }

  Future<void> _onPreprocessingRetry(
    PreprocessingRetry event,
    Emitter<SceneState> emit,
  ) async {
    final params = _lastPrepareParams;
    if (params == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }
    await _prepareScene(
      tmdbId: params.tmdbId,
      mediaType: params.mediaType,
      episode: params.episode,
      emit: emit,
    );
  }

  void _onTimestampScrubbed(
    TimestampScrubbed event,
    Emitter<SceneState> emit,
  ) {
    _contextRequestId++;
    _emitPreprocessedPreview(event.timestampMs, emit);
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

  Future<void> _prepareScene({
    required int tmdbId,
    required MediaType mediaType,
    required TvEpisodeSelection? episode,
    required Emitter<SceneState> emit,
  }) async {
    _lastPrepareParams = _PrepareParams(
      tmdbId: tmdbId,
      mediaType: mediaType,
      episode: episode,
    );

    emit(const SceneLoading());

    final detail = _session.titleDetail;
    if (detail == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }

    await _loadSceneCast(detail: detail, episode: episode);

    if (mediaType == MediaType.tv) {
      final playbackResult = await _repository.ensureTitlePlayback(
        tmdbId: tmdbId,
        mediaType: mediaType,
        episode: episode,
        titleLabel: detail.summary.displayLabel,
        imdbId: detail.imdbId,
      );
      switch (playbackResult) {
        case Success():
          break;
        case Error(:final failure):
          emit(SceneFailure(failure));
          return;
      }
    }

    await _waitForPreprocessing(
      tmdbId: tmdbId,
      mediaType: mediaType,
      episode: episode,
      titleLabel: detail.summary.displayLabel,
      imdbId: detail.imdbId,
      emit: emit,
    );
  }

  Future<void> _waitForPreprocessing({
    required int tmdbId,
    required MediaType mediaType,
    required TvEpisodeSelection? episode,
    required String? titleLabel,
    required String? imdbId,
    required Emitter<SceneState> emit,
  }) async {
    final deadline = DateTime.now().add(_preprocessingTimeout);

    while (DateTime.now().isBefore(deadline)) {
      final result = await _repository.getTitlePreprocessing(
        tmdbId: tmdbId,
        mediaType: mediaType,
        episode: episode,
        titleLabel: titleLabel,
        imdbId: imdbId,
      );

      switch (result) {
        case Success(:final data):
          if (data.isReady) {
            final breakdown = data.breakdown;
            if (breakdown != null) {
              _session.setDurationMs(breakdown.durationMs);
              _session.setTitleBreakdown(breakdown);
            }
            emit(const SceneAwaitingTimestamp());
            return;
          }
        case Error(:final failure):
          emit(ScenePreprocessingFailure(failure));
          return;
      }

      await Future<void>.delayed(_preprocessingPollInterval);
    }

    emit(
      const ScenePreprocessingFailure(
        ServerFailure(
          'El análisis del título está tardando más de lo esperado. '
          'Inténtalo de nuevo en unos minutos.',
        ),
      ),
    );
  }

  void _emitPreprocessedPreview(int timestampMs, Emitter<SceneState> emit) {
    final detail = _session.titleDetail;
    if (detail == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }

    final breakdown = _session.titleBreakdown;
    if (breakdown == null || !breakdown.hasScenes) {
      return;
    }

    final segment = resolveSceneAtTimestamp(breakdown.scenes, timestampMs);
    final preprocessedSummary = segment?.displaySummary ?? '';
    final characters = segment == null
        ? const <SceneCharacter>[]
        : resolvePreprocessedCharacters(
            segment.characters,
            _session.sceneCast,
          );
    final previous = state;
    final previousLoaded = previous is SceneLoaded ? previous : null;

    emit(
      SceneLoaded(
        timestampMs: timestampMs,
        context: previousLoaded?.context ??
            _placeholderContext(
              timestampMs: timestampMs,
              titleLabel: detail.summary.displayLabel,
            ),
        characters: characters,
        preprocessedSummary: preprocessedSummary,
        summary: null,
        questions: previousLoaded?.questions ?? const [],
        briefUsage: previousLoaded?.briefUsage,
        briefError: null,
        isPreview: true,
      ),
    );
  }

  Future<void> _loadContext(int timestampMs, Emitter<SceneState> emit) async {
    final detail = _session.titleDetail;
    if (detail == null) {
      emit(const SceneFailure(NotFoundFailure('Title not available')));
      return;
    }

    final breakdown = _session.titleBreakdown;
    final cast = _session.sceneCast;
    final requestId = ++_contextRequestId;

    if (breakdown != null && breakdown.hasScenes) {
      final segment = resolveSceneAtTimestamp(breakdown.scenes, timestampMs);
      final preprocessedSummary = segment?.displaySummary ?? '';
      final characters = segment == null
          ? const <SceneCharacter>[]
          : resolvePreprocessedCharacters(segment.characters, cast);
      final previous = state;
      final previousLoaded = previous is SceneLoaded ? previous : null;

      emit(
        SceneLoaded(
          timestampMs: timestampMs,
          context: previousLoaded?.context ??
              _placeholderContext(
                timestampMs: timestampMs,
                titleLabel: detail.summary.displayLabel,
              ),
          characters: characters,
          preprocessedSummary: preprocessedSummary,
          summary: null,
          questions: previousLoaded?.questions ?? const [],
          briefUsage: previousLoaded?.briefUsage,
          isBriefLoading: true,
          isPreview: false,
        ),
      );
    } else {
      emit(const SceneLoading());
    }

    final mediaType = detail.summary.mediaType;
    final result = await _repository.getContext(
      tmdbId: detail.summary.id,
      mediaType: mediaType,
      timestampMs: timestampMs,
      episode: mediaType == MediaType.tv ? _session.selectedEpisode : null,
      titleLabel: detail.summary.displayLabel,
      imdbId: detail.imdbId,
    );

    if (requestId != _contextRequestId) {
      return;
    }

    switch (result) {
      case Success(:final data):
        _session.setSceneContext(data.context);
        final brief = data.brief;
        final currentState = state;
        final fallbackSummary = currentState is SceneLoaded
            ? currentState.preprocessedSummary
            : null;
        final characters = brief != null
            ? resolveBriefCharacters(brief.presentCharacterNames, cast)
            : (currentState is SceneLoaded
                ? currentState.characters
                : <SceneCharacter>[]);
        final briefSummary = brief?.summary.trim();
        emit(
          SceneLoaded(
            timestampMs: timestampMs,
            context: data.context,
            characters: characters,
            preprocessedSummary: fallbackSummary,
            summary: briefSummary != null && briefSummary.isNotEmpty
                ? briefSummary
                : fallbackSummary,
            questions: brief?.questions ?? const [],
            briefUsage: brief?.usage,
            briefError: brief == null || (brief.summary.isEmpty)
                ? (fallbackSummary == null || fallbackSummary.isEmpty
                    ? 'No se pudo generar el resumen automático. Puedes preguntar abajo.'
                    : null)
                : null,
            isBriefLoading: false,
            isPreview: false,
          ),
        );
      case Error(:final failure):
        if (breakdown != null && breakdown.hasScenes) {
          final currentState = state;
          if (currentState is SceneLoaded) {
            emit(
              currentState.copyWithBriefFinished(
                briefError: failure.message,
              ),
            );
            return;
          }
        }
        emit(SceneFailure(failure));
    }
  }

  SceneContext _placeholderContext({
    required int timestampMs,
    required String? titleLabel,
  }) {
    return SceneContext(
      timestampMs: timestampMs,
      sceneBeforeSeconds: 120,
      sceneAfterSeconds: 30,
      dialogueText: '',
      askDialogueText: '',
      priorDialogueText: '',
      titleLabel: titleLabel,
    );
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

class _PrepareParams {
  const _PrepareParams({
    required this.tmdbId,
    required this.mediaType,
    required this.episode,
  });

  final int tmdbId;
  final MediaType mediaType;
  final TvEpisodeSelection? episode;
}

extension on SceneLoaded {
  SceneLoaded copyWithBriefFinished({String? briefError}) {
    return SceneLoaded(
      timestampMs: timestampMs,
      context: context,
      characters: characters,
      summary: summary,
      preprocessedSummary: preprocessedSummary,
      questions: questions,
      briefUsage: briefUsage,
      briefError: briefError ?? this.briefError,
      isBriefLoading: false,
      isPreview: false,
    );
  }
}
