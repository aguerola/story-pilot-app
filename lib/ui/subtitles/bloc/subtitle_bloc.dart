import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
import 'package:storypilot/data/services/settings_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/subtitles/bloc/subtitle_event.dart';
import 'package:storypilot/ui/subtitles/bloc/subtitle_state.dart';

class SubtitleBloc extends Bloc<SubtitleEvent, SubtitleState> {
  SubtitleBloc(
    this._repository,
    this._settings,
    this._session,
  ) : super(const SubtitleInitial()) {
    on<SubtitleTracksRequested>(_onTracksRequested);
    on<SubtitleLanguageChanged>(_onLanguageChanged);
    on<SubtitleDownloadRequested>(_onDownloadRequested);
  }

  final SubtitleRepository _repository;
  final SettingsService _settings;
  final TitleSessionHolder _session;

  int? _tmdbId;
  MediaType? _mediaType;

  Future<void> _onTracksRequested(
    SubtitleTracksRequested event,
    Emitter<SubtitleState> emit,
  ) async {
    _tmdbId = event.tmdbId;
    _mediaType = event.mediaType;
    final language = event.language ?? _settings.subtitleLanguage;
    emit(const SubtitleLoading());
    final result = await _repository.listTracks(
      tmdbId: event.tmdbId,
      mediaType: event.mediaType,
      language: language,
    );
    switch (result) {
      case Success(:final data):
        emit(SubtitleTracksLoaded(tracks: data, language: language));
      case Error(:final failure):
        emit(SubtitleFailure(failure));
    }
  }

  Future<void> _onLanguageChanged(
    SubtitleLanguageChanged event,
    Emitter<SubtitleState> emit,
  ) async {
    await _settings.setSubtitleLanguage(event.language);
    if (_tmdbId != null && _mediaType != null) {
      add(
        SubtitleTracksRequested(
          tmdbId: _tmdbId!,
          mediaType: _mediaType!,
          language: event.language,
        ),
      );
    }
  }

  Future<void> _onDownloadRequested(
    SubtitleDownloadRequested event,
    Emitter<SubtitleState> emit,
  ) async {
    emit(SubtitleDownloading(event.track));
    final result = await _repository.downloadAndParse(
      tmdbId: event.tmdbId,
      track: event.track,
    );
    switch (result) {
      case Success(:final data):
        _session.setSubtitleDocument(data);
        emit(SubtitleDownloaded(data));
      case Error(:final failure):
        emit(SubtitleFailure(failure));
    }
  }
}
