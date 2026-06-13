import 'package:equatable/equatable.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
