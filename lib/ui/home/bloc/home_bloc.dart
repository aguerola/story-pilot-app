import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/home/bloc/home_event.dart';
import 'package:storypilot/ui/home/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository, this._history)
      : super(const HomeInitial()) {
    on<HomeRequested>(_onRequested);
  }

  final TitleRepository _repository;
  final BrowseHistoryService _history;

  Future<void> _onRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final recentSeries = await _history.getRecentSeries();
    final recentMovies = await _history.getRecentMovies();
    final popularMoviesResult = await _repository.getPopularMovies();
    final popularSeriesResult = await _repository.getPopularSeries();

    if (popularMoviesResult case Error(:final failure)) {
      emit(HomeFailure(failure));
      return;
    }
    if (popularSeriesResult case Error(:final failure)) {
      emit(HomeFailure(failure));
      return;
    }

    final popularMovies =
        (popularMoviesResult as Success<List<TitleSummary>>).data;
    final popularSeries =
        (popularSeriesResult as Success<List<TitleSummary>>).data;

    emit(
      HomeLoaded(
        recentSeries: recentSeries,
        recentMovies: recentMovies,
        popularMovies: popularMovies,
        popularSeries: popularSeries,
      ),
    );
  }
}
