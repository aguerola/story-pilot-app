import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/ui/search/bloc/search_bloc.dart';
import 'package:storypilot/ui/search/bloc/search_event.dart';
import 'package:storypilot/ui/search/bloc/search_state.dart';

class MockTitleRepository extends Mock implements TitleRepository {}

void main() {
  late MockTitleRepository repository;
  late SearchBloc bloc;

  setUp(() {
    repository = MockTitleRepository();
    bloc = SearchBloc(repository);
  });

  tearDown(() => bloc.close());

  blocTest<SearchBloc, SearchState>(
    'emits initial when query is empty',
    build: () => bloc,
    act: (bloc) => bloc.add(const SearchSubmitted('')),
    expect: () => [const SearchInitial()],
  );

  blocTest<SearchBloc, SearchState>(
    'emits loaded on success',
    build: () {
      when(() => repository.search('matrix')).thenAnswer(
        (_) async => const Success([
          TitleSummary(
            id: 1,
            mediaType: MediaType.movie,
            title: 'The Matrix',
            year: 1999,
          ),
        ]),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const SearchSubmitted('matrix')),
    expect: () => [
      const SearchLoading(),
      isA<SearchLoaded>(),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'emits failure on error',
    build: () {
      when(() => repository.search('fail')).thenAnswer(
        (_) async => const Error(NetworkFailure('offline')),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const SearchSubmitted('fail')),
    expect: () => [
      const SearchLoading(),
      const SearchFailure(NetworkFailure('offline')),
    ],
  );
}
