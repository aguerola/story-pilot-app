import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/services/tmdb_functions_client.dart';

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late MockHttpsCallableResult result;
  late FirebaseTmdbFunctionsClient client;

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    result = MockHttpsCallableResult();
    client = FirebaseTmdbFunctionsClient(functions: functions);

    when(() => functions.httpsCallable('tmdb')).thenReturn(callable);
  });

  test('calls tmdb with payload and returns response map', () async {
    when(() => callable.call(any())).thenAnswer((_) async => result);
    when(() => result.data).thenReturn({
      'results': [
        {'id': 550, 'title': 'Fight Club'},
      ],
    });

    final response = await client.call({
      'op': 'popularMovies',
    });

    expect(response['results'], isA<List<dynamic>>());
    final captured = verify(() => callable.call(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(captured['op'], 'popularMovies');
  });
}
