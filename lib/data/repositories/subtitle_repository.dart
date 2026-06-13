import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/open_subtitles_service.dart';
import 'package:storypilot/data/services/subtitle_parser_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/domain/models/subtitle_track.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';

class SubtitleRepository {
  SubtitleRepository(
    this._openSubtitles,
    this._parser,
    this._cache,
  );

  static const subtitleLanguage = 'en';

  final OpenSubtitlesService _openSubtitles;
  final SubtitleParserService _parser;
  final LocalCacheService _cache;

  Future<Result<List<SubtitleTrack>>> listTracks({
    required int tmdbId,
    required MediaType mediaType,
    required String language,
    TvEpisodeSelection? episode,
  }) {
    return _openSubtitles.listTracks(
      tmdbId: tmdbId,
      mediaType: mediaType,
      language: language,
      seasonNumber: episode?.seasonNumber,
      episodeNumber: episode?.episodeNumber,
    );
  }

  Future<Result<SubtitleDocument>> downloadAndParse({
    required int tmdbId,
    required SubtitleTrack track,
    TvEpisodeSelection? episode,
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

    await _cache.saveSubtitle(
      document,
      seasonNumber: episode?.seasonNumber,
      episodeNumber: episode?.episodeNumber,
    );
    return Success(document);
  }

  Future<SubtitleDocument?> getCachedForTitle(
    int tmdbId, {
    TvEpisodeSelection? episode,
  }) {
    return _cache.getLatestSubtitleForTitle(
      tmdbId,
      seasonNumber: episode?.seasonNumber,
      episodeNumber: episode?.episodeNumber,
    );
  }

  Future<Result<SubtitleDocument>> ensureSubtitleForTitle({
    required int tmdbId,
    required MediaType mediaType,
    TvEpisodeSelection? episode,
  }) async {
    final cached = await getCachedForTitle(tmdbId, episode: episode);
    if (cached != null && cached.language == subtitleLanguage) {
      return Success(cached);
    }

    final tracksResult = await listTracks(
      tmdbId: tmdbId,
      mediaType: mediaType,
      language: subtitleLanguage,
      episode: episode,
    );
    if (tracksResult is Error<List<SubtitleTrack>>) {
      return Error(tracksResult.failure);
    }

    final srtTracks = (tracksResult as Success<List<SubtitleTrack>>)
        .data
        .where((track) => track.format.toLowerCase() == 'srt')
        .toList();
    if (srtTracks.isEmpty) {
      return const Error(
        NotFoundFailure('No English SRT subtitles found'),
      );
    }

    final bestTrack = srtTracks.reduce(
      (a, b) =>
          (a.downloadCount ?? 0) >= (b.downloadCount ?? 0) ? a : b,
    );

    return downloadAndParse(
      tmdbId: tmdbId,
      track: bestTrack,
      episode: episode,
    );
  }
}
