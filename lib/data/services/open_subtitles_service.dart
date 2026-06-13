import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:storypilot/config/env.dart';
import 'package:storypilot/data/services/subtitle_functions_client.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_track.dart';
import 'package:storypilot/domain/result.dart';

class OpenSubtitlesService {
  OpenSubtitlesService(
    this._dio, {
    SubtitleFunctionsClient? functionsClient,
    @visibleForTesting bool? useStoryPilotServer,
  })  : _functionsClient = functionsClient,
        _useStoryPilotServerOverride = useStoryPilotServer;

  final Dio _dio;
  final SubtitleFunctionsClient? _functionsClient;
  final bool? _useStoryPilotServerOverride;

  Future<Result<List<SubtitleTrack>>> listTracks({
    required int tmdbId,
    required MediaType mediaType,
    required String language,
  }) async {
    if (!_isConfigured) {
      return const Error(
        NetworkFailure('OpenSubtitles not configured'),
      );
    }
    try {
      final type = mediaType == MediaType.movie ? 'movie' : 'episode';
      final Map<String, dynamic> payload;
      if (_useStoryPilotServer) {
        payload = await _functionsClient!.listSubtitles(
          tmdbId: tmdbId,
          type: type,
          languages: language,
        );
      } else {
        final response = await _dio.get<Map<String, dynamic>>(
          Env.wrapUrl('${Env.openSubtitlesBaseUrl}/subtitles'),
          queryParameters: {
            'tmdb_id': tmdbId,
            'type': type,
            'languages': language,
          },
          options: Options(headers: _directHeaders),
        );
        payload = response.data ?? {};
      }

      final data = payload['data'] as List<dynamic>? ?? [];
      final tracks = data.whereType<Map<String, dynamic>>().map((item) {
        final attrs = item['attributes'] as Map<String, dynamic>? ?? item;
        final files = attrs['files'] as List<dynamic>? ?? [];
        final fileId = files.isNotEmpty
            ? (files.first as Map<String, dynamic>)['file_id']?.toString() ??
                ''
            : attrs['file_id']?.toString() ?? '';
        return SubtitleTrack(
          fileId: fileId,
          language:
              (attrs['language'] as String? ?? language).split('-').first,
          downloadCount: attrs['download_count'] as int?,
          format: attrs['format'] as String? ?? 'srt',
        );
      }).where((t) => t.fileId.isNotEmpty).toList();
      return Success(tracks);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<String>> downloadSubtitleContent(String fileId) async {
    if (!_isConfigured) {
      return const Error(
        NetworkFailure('OpenSubtitles not configured'),
      );
    }
    try {
      if (_useStoryPilotServer) {
        final content =
            await _functionsClient!.downloadSubtitleContent(fileId);
        return Success(content);
      }

      final response = await _dio.post<Map<String, dynamic>>(
        Env.wrapUrl('${Env.openSubtitlesBaseUrl}/download'),
        data: {'file_id': int.tryParse(fileId) ?? fileId},
        options: Options(headers: _directHeaders),
      );
      final link = response.data?['link'] as String?;
      if (link == null) {
        return const Error(NotFoundFailure('Download link not available'));
      }
      final fileResponse = await _dio.get<String>(
        Env.wrapCrossOriginFileUrl(link),
      );
      return Success(fileResponse.data ?? '');
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  bool get _isConfigured {
    if (_useStoryPilotServer) {
      return _functionsClient != null;
    }
    return Env.hasOpenSubtitlesKey;
  }

  bool get _useStoryPilotServer =>
      _useStoryPilotServerOverride ?? Env.useStoryPilotServer;

  Map<String, String> get _directHeaders => {
    'Api-Key': Env.openSubtitlesApiKey,
    'User-Agent': 'StoryPilot v1.0',
  };

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    return ServerFailure(e.message ?? 'OpenSubtitles request failed');
  }
}
