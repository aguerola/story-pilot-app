import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_summary.dart';

void main() {
  late SharedPreferences prefs;
  late BrowseHistoryService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = BrowseHistoryService(prefs);
  });

  const movie1 = TitleSummary(
    id: 1,
    mediaType: MediaType.movie,
    title: 'Movie One',
    year: 2020,
  );

  const movie2 = TitleSummary(
    id: 2,
    mediaType: MediaType.movie,
    title: 'Movie Two',
    year: 2021,
  );

  const series1 = TitleSummary(
    id: 10,
    mediaType: MediaType.tv,
    title: 'Series One',
    year: 2019,
  );

  test('stores movies and series separately', () async {
    await service.recordView(movie1);
    await service.recordView(series1);

    expect(await service.getRecentMovies(), [movie1]);
    expect(await service.getRecentSeries(), [series1]);
  });

  test('moves duplicate to front', () async {
    await service.recordView(movie1);
    await service.recordView(movie2);
    await service.recordView(movie1);

    expect(await service.getRecentMovies(), [movie1, movie2]);
  });

  test('respects max items limit', () async {
    for (var i = 0; i < BrowseHistoryService.maxItems + 5; i++) {
      await service.recordView(
        TitleSummary(
          id: i,
          mediaType: MediaType.movie,
          title: 'Movie $i',
        ),
      );
    }

    final recent = await service.getRecentMovies();
    expect(recent.length, BrowseHistoryService.maxItems);
    expect(recent.first.id, BrowseHistoryService.maxItems + 4);
  });
}
