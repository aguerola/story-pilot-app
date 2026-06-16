import 'package:cloud_functions/cloud_functions.dart';

abstract class TmdbFunctionsClient {
  Future<Map<String, dynamic>> call(Map<String, dynamic> payload);
}

class FirebaseTmdbFunctionsClient implements TmdbFunctionsClient {
  FirebaseTmdbFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> payload) async {
    final result = await _functions.httpsCallable('tmdb').call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }
}
