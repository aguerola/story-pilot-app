import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/search/bloc/search_event.dart';
import 'package:storypilot/ui/search/bloc/search_state.dart';
import 'package:stream_transform/stream_transform.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repository) : super(const SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 400)),
    );
    on<SearchSubmitted>(_onSubmitted);
  }

  final TitleRepository _repository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    await _search(event.query, emit);
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    await _search(event.query, emit);
  }

  Future<void> _search(String query, Emitter<SearchState> emit) async {
    if (query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }
    emit(const SearchLoading());
    final result = await _repository.search(query);
    switch (result) {
      case Success(:final data):
        emit(SearchLoaded(data));
      case Error(:final failure):
        emit(SearchFailure(failure));
    }
  }
}
