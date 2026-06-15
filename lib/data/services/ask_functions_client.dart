import 'package:cloud_functions/cloud_functions.dart';

abstract class AskFunctionsClient {
  Future<Map<String, dynamic>> sceneAsk({
    required Map<String, dynamic> context,
    required String question,
    String? modelId,
  });

  Future<Map<String, dynamic>> sceneBrief({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> cast,
    String? modelId,
  });
}

class FirebaseAskFunctionsClient implements AskFunctionsClient {
  FirebaseAskFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> sceneAsk({
    required Map<String, dynamic> context,
    required String question,
    String? modelId,
  }) async {
    final payload = <String, dynamic>{
      'context': context,
      'question': question,
    };
    if (modelId != null) payload['modelId'] = modelId;
    final result = await _functions.httpsCallable('sceneAsk').call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<Map<String, dynamic>> sceneBrief({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> cast,
    String? modelId,
  }) async {
    final payload = <String, dynamic>{
      'context': context,
      'cast': cast,
    };
    if (modelId != null) payload['modelId'] = modelId;
    final result = await _functions.httpsCallable('sceneBrief').call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }
}
