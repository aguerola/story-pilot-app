import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/title_summary.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded(this.results);

  final List<TitleSummary> results;

  @override
  List<Object?> get props => [results];
}

final class SearchFailure extends SearchState {
  const SearchFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
