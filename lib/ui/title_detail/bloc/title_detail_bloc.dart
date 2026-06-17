import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_event.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_state.dart';

class TitleDetailBloc extends Bloc<TitleDetailEvent, TitleDetailState> {
  TitleDetailBloc(
    this._repository,
    this._sceneRepository,
    this._session,
    this._history,
  ) : super(const TitleDetailInitial()) {
    on<TitleDetailRequested>(_onRequested);
  }

  final TitleRepository _repository;
  final SceneRepository _sceneRepository;
  final TitleSessionHolder _session;
  final BrowseHistoryService _history;

  Future<void> _onRequested(
    TitleDetailRequested event,
    Emitter<TitleDetailState> emit,
  ) async {
    emit(const TitleDetailLoading());
    final result = await _repository.getDetail(event.id, event.mediaType);
    switch (result) {
      case Success(:final data):
        _session.setTitleDetail(data);
        await _history.recordView(data.summary);
        emit(TitleDetailLoaded(data));
        if (data.summary.mediaType == MediaType.movie) {
          unawaited(_ensureMoviePlayback(data));
        }
      case Error(:final failure):
        emit(TitleDetailFailure(failure));
    }
  }

  Future<void> _ensureMoviePlayback(TitleDetail data) async {
    final result = await _sceneRepository.ensureTitlePlayback(
      tmdbId: data.summary.id,
      mediaType: MediaType.movie,
      titleLabel: data.summary.displayLabel,
      imdbId: data.imdbId,
    );
    if (result is Error<int>) {
      developer.log(
        'ensureTitlePlayback failed on title detail',
        name: 'TitleDetailBloc',
        error: result.failure.message,
      );
    }
  }
}
