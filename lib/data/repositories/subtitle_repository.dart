import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/open_subtitles_service.dart';
import 'package:storypilot/data/services/subtitle_parser_service.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/domain/models/subtitle_track.dart';
import 'package:storypilot/domain/result.dart';

class SubtitleRepository {
  SubtitleRepository(
    this._openSubtitles,
    this._parser,
    this._cache,
  );

  final OpenSubtitlesService _openSubtitles;
  final SubtitleParserService _parser;
  final LocalCacheService _cache;

  Future<Result<List<SubtitleTrack>>> listTracks({
    required int tmdbId,
    required MediaType mediaType,
    required String language,
  }) {
    return _openSubtitles.listTracks(
      tmdbId: tmdbId,
      mediaType: mediaType,
      language: language,
    );
  }

  Future<Result<SubtitleDocument>> downloadAndParse({
    required int tmdbId,
    required SubtitleTrack track,
  }) async {
    final cached = await _cache.getSubtitle(
      tmdbId,
      track.language,
      track.fileId,
    );
    if (cached != null) {
      return Success(cached);
    }

    final download = await _openSubtitles.downloadSubtitleContent(track.fileId);
    if (download is Error<String>) {
      return Error(download.failure);
    }

    final parsed = _parser.parseSrt((download as Success<String>).data);
    if (parsed is Error<List<SubtitleLine>>) {
      return Error(parsed.failure);
    }

    final document = SubtitleDocument(
      titleId: tmdbId,
      language: track.language,
      fileId: track.fileId,
      lines: (parsed as Success<List<SubtitleLine>>).data,
    );

    await _cache.saveSubtitle(document);
    return Success(document);
  }
}
