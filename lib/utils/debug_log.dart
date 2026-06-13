import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _logPath =
    '/Users/antoniomartinezguerola/dev/projects/story-pilot/.cursor/debug-f6d29b.log';
const _endpoint =
    'http://127.0.0.1:7884/ingest/6f08639c-2230-422e-b7e2-dbae4e5f4e0b';
const _sessionId = 'f6d29b';

void debugLog({
  required String location,
  required String message,
  required Map<String, dynamic> data,
  required String hypothesisId,
  String runId = 'pre-fix',
}) {
  final payload = {
    'sessionId': _sessionId,
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = '${jsonEncode(payload)}\n';

  // #region agent log
  if (!kIsWeb) {
    try {
      File(_logPath).writeAsStringSync(line, mode: FileMode.append);
    } catch (_) {}
  }
  Dio()
      .post(
        _endpoint,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': _sessionId,
          },
        ),
      )
      .catchError((_) => Response(requestOptions: RequestOptions(path: _endpoint)));
  // #endregion
}
