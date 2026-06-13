import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/services/open_subtitles_service.dart';
import 'package:storypilot/data/services/subtitle_functions_client.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/result.dart';

class _MockSubtitleFunctionsClient extends Mock
    implements SubtitleFunctionsClient {}

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockSubtitleFunctionsClient functionsClient;
  late _MockDio dio;
  late OpenSubtitlesService service;

  setUp(() {
    functionsClient = _MockSubtitleFunctionsClient();
    dio = _MockDio();
    service = OpenSubtitlesService(
      dio,
      functionsClient: functionsClient,
      useStoryPilotServer: true,
    );
  });

  test('listTracks uses Firebase callable client', () async {
    when(
      () => functionsClient.listSubtitles(
        tmdbId: 550,
        type: 'movie',
        languages: 'en',
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {
            'attributes': {
              'language': 'en',
              'format': 'srt',
              'download_count': 10,
              'files': [
                {'file_id': 123},
              ],
            },
          },
        ],
      },
    );

    final result = await service.listTracks(
      tmdbId: 550,
      mediaType: MediaType.movie,
      language: 'en',
    );

    expect(result, isA<Success<List<dynamic>>>());
    verify(
      () => functionsClient.listSubtitles(
        tmdbId: 550,
        type: 'movie',
        languages: 'en',
      ),
    ).called(1);
  });

  test('downloadSubtitleContent uses Firebase callable client', () async {
    when(
      () => functionsClient.downloadSubtitleContent('123'),
    ).thenAnswer((_) async => '1\n00:00:01,000 --> 00:00:02,000\nHello');

    final result = await service.downloadSubtitleContent('123');

    expect(result, isA<Success<String>>());
    expect((result as Success<String>).data, contains('Hello'));
  });
}
