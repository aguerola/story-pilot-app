import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/title_summary.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.recentSeries,
    required this.recentMovies,
    required this.popularMovies,
    required this.popularSeries,
  });

  final List<TitleSummary> recentSeries;
  final List<TitleSummary> recentMovies;
  final List<TitleSummary> popularMovies;
  final List<TitleSummary> popularSeries;

  @override
  List<Object?> get props => [
        recentSeries,
        recentMovies,
        popularMovies,
        popularSeries,
      ];
}

class HomeFailure extends HomeState {
  const HomeFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
