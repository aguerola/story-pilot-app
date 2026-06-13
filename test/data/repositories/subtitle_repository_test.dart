import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
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

class MockOpenSubtitlesService extends Mock implements OpenSubtitlesService {}

class MockSubtitleParserService extends Mock implements SubtitleParserService {}

class MockLocalCacheService extends Mock implements LocalCacheService {}

void main() {
  late MockOpenSubtitlesService openSubtitles;
  late MockSubtitleParserService parser;
  late MockLocalCacheService cache;
  late SubtitleRepository repository;

  const tmdbId = 1;
  const mediaType = MediaType.movie;

  final cachedDocument = SubtitleDocument(
    titleId: tmdbId,
    language: 'en',
    fileId: 'cached',
    lines: const [
      SubtitleLine(startMs: 0, endMs: 1000, text: 'Cached line'),
    ],
  );

  setUpAll(() {
    registerFallbackValue(cachedDocument);
    registerFallbackValue(const TvEpisodeSelection(
      seasonNumber: 1,
      episodeNumber: 1,
    ));
  });

  setUp(() {
    openSubtitles = MockOpenSubtitlesService();
    parser = MockSubtitleParserService();
    cache = MockLocalCacheService();
    repository = SubtitleRepository(openSubtitles, parser, cache);
  });

  test('returns cached English subtitle without listing tracks', () async {
    when(() => cache.getLatestSubtitleForTitle(tmdbId))
        .thenAnswer((_) async => cachedDocument);

    final result = await repository.ensureSubtitleForTitle(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );

    expect(result, isA<Success<SubtitleDocument>>());
    expect((result as Success<SubtitleDocument>).data, cachedDocument);
    verifyNever(
      () => openSubtitles.listTracks(
        tmdbId: tmdbId,
        mediaType: mediaType,
        language: 'en',
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    );
  });

  test('ignores non-English cache and downloads best SRT track', () async {
    final spanishCache = SubtitleDocument(
      titleId: tmdbId,
      language: 'es',
      fileId: 'es-file',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 1000, text: 'Hola'),
      ],
    );
    const tracks = [
      SubtitleTrack(
        fileId: 'low',
        language: 'en',
        downloadCount: 10,
        format: 'srt',
      ),
      SubtitleTrack(
        fileId: 'high',
        language: 'en',
        downloadCount: 100,
        format: 'srt',
      ),
      SubtitleTrack(
        fileId: 'ass',
        language: 'en',
        downloadCount: 999,
        format: 'ass',
      ),
    ];
    const srt = '''
1
00:00:00,000 --> 00:00:01,000
Hello
''';
    final downloadedDocument = SubtitleDocument(
      titleId: tmdbId,
      language: 'en',
      fileId: 'high',
      lines: const [
        SubtitleLine(startMs: 0, endMs: 1000, text: 'Hello'),
      ],
    );

    when(() => cache.getLatestSubtitleForTitle(tmdbId))
        .thenAnswer((_) async => spanishCache);
    when(
      () => openSubtitles.listTracks(
        tmdbId: tmdbId,
        mediaType: mediaType,
        language: 'en',
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((_) async => const Success(tracks));
    when(() => cache.getSubtitle(tmdbId, 'en', 'high'))
        .thenAnswer((_) async => null);
    when(() => openSubtitles.downloadSubtitleContent('high'))
        .thenAnswer((_) async => const Success(srt));
    when(() => parser.parseSrt(srt))
        .thenReturn(Success(downloadedDocument.lines));
    when(() => cache.saveSubtitle(any()))
        .thenAnswer((_) async => const Success(null));

    final result = await repository.ensureSubtitleForTitle(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );

    expect(result, isA<Success<SubtitleDocument>>());
    final document = (result as Success<SubtitleDocument>).data;
    expect(document.fileId, 'high');
    verify(() => openSubtitles.downloadSubtitleContent('high')).called(1);
    verifyNever(() => openSubtitles.downloadSubtitleContent('low'));
    verifyNever(() => openSubtitles.downloadSubtitleContent('ass'));
  });

  test('returns not found when no English SRT tracks exist', () async {
    when(() => cache.getLatestSubtitleForTitle(tmdbId))
        .thenAnswer((_) async => null);
    when(
      () => openSubtitles.listTracks(
        tmdbId: tmdbId,
        mediaType: mediaType,
        language: 'en',
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer(
      (_) async => const Success([
        SubtitleTrack(
          fileId: 'ass',
          language: 'en',
          downloadCount: 50,
          format: 'ass',
        ),
      ]),
    );

    final result = await repository.ensureSubtitleForTitle(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );

    expect(result, isA<Error<SubtitleDocument>>());
    expect(
      (result as Error<SubtitleDocument>).failure,
      isA<NotFoundFailure>(),
    );
  });
}
