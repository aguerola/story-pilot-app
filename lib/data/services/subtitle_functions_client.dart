import 'package:cloud_functions/cloud_functions.dart';

abstract class SubtitleFunctionsClient {
  Future<Map<String, dynamic>> listSubtitles({
    required int tmdbId,
    required String type,
    required String languages,
  });

  Future<String> downloadSubtitleContent(String fileId);
}

class FirebaseSubtitleFunctionsClient implements SubtitleFunctionsClient {
  FirebaseSubtitleFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        );

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> listSubtitles({
    required int tmdbId,
    required String type,
    required String languages,
  }) async {
    final result = await _functions.httpsCallable('listSubtitles').call({
      'tmdbId': tmdbId,
      'type': type,
      'languages': languages,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<String> downloadSubtitleContent(String fileId) async {
    final parsedId = int.tryParse(fileId) ?? fileId;
    final result =
        await _functions.httpsCallable('downloadSubtitle').call({
      'fileId': parsedId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['content'] as String? ?? '';
  }
}
