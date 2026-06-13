import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_event.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_state.dart';

class TitleDetailBloc extends Bloc<TitleDetailEvent, TitleDetailState> {
  TitleDetailBloc(this._repository, this._session)
      : super(const TitleDetailInitial()) {
    on<TitleDetailRequested>(_onRequested);
  }

  final TitleRepository _repository;
  final TitleSessionHolder _session;

  Future<void> _onRequested(
    TitleDetailRequested event,
    Emitter<TitleDetailState> emit,
  ) async {
    emit(const TitleDetailLoading());
    final result = await _repository.getDetail(event.id, event.mediaType);
    switch (result) {
      case Success(:final data):
        _session.setTitleDetail(data);
        emit(TitleDetailLoaded(data));
      case Error(:final failure):
        emit(TitleDetailFailure(failure));
    }
  }
}
