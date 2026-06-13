import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/home/bloc/home_bloc.dart';
import 'package:storypilot/ui/home/bloc/home_event.dart';
import 'package:storypilot/ui/home/bloc/home_state.dart';

class MockTitleRepository extends Mock implements TitleRepository {}

class MockBrowseHistoryService extends Mock implements BrowseHistoryService {}

void main() {
  late MockTitleRepository repository;
  late MockBrowseHistoryService history;
  late HomeBloc bloc;

  const recentSeries = [
    TitleSummary(
      id: 1,
      mediaType: MediaType.tv,
      title: 'Recent Series',
    ),
  ];

  const recentMovies = [
    TitleSummary(
      id: 2,
      mediaType: MediaType.movie,
      title: 'Recent Movie',
    ),
  ];

  const popularMovies = [
    TitleSummary(
      id: 3,
      mediaType: MediaType.movie,
      title: 'Popular Movie',
    ),
  ];

  const popularSeries = [
    TitleSummary(
      id: 4,
      mediaType: MediaType.tv,
      title: 'Popular Series',
    ),
  ];

  setUp(() {
    repository = MockTitleRepository();
    history = MockBrowseHistoryService();
    bloc = HomeBloc(repository, history);
  });

  tearDown(() => bloc.close());

  blocTest<HomeBloc, HomeState>(
    'emits HomeLoaded with combined data',
    build: () {
      when(() => history.getRecentSeries()).thenAnswer((_) async => recentSeries);
      when(() => history.getRecentMovies()).thenAnswer((_) async => recentMovies);
      when(() => repository.getPopularMovies())
          .thenAnswer((_) async => const Success(popularMovies));
      when(() => repository.getPopularSeries())
          .thenAnswer((_) async => const Success(popularSeries));
      return bloc;
    },
    act: (bloc) => bloc.add(const HomeRequested()),
    expect: () => [
      const HomeLoading(),
      const HomeLoaded(
        recentSeries: recentSeries,
        recentMovies: recentMovies,
        popularMovies: popularMovies,
        popularSeries: popularSeries,
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'emits HomeFailure when popular movies fail',
    build: () {
      when(() => history.getRecentSeries()).thenAnswer((_) async => []);
      when(() => history.getRecentMovies()).thenAnswer((_) async => []);
      when(() => repository.getPopularMovies()).thenAnswer(
        (_) async => const Error(NetworkFailure('offline')),
      );
      when(() => repository.getPopularSeries())
          .thenAnswer((_) async => const Success([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const HomeRequested()),
    expect: () => [
      const HomeLoading(),
      const HomeFailure(NetworkFailure('offline')),
    ],
  );
}
