import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/title_summary.dart';

class BrowseHistoryService {
  BrowseHistoryService(this._prefs);

  static const maxItems = 20;
  static const _moviesKey = 'browse_history_movies';
  static const _seriesKey = 'browse_history_series';

  final SharedPreferences _prefs;

  Future<void> recordView(TitleSummary summary) async {
    final key = summary.mediaType == MediaType.movie ? _moviesKey : _seriesKey;
    final current = await _load(key);
    final updated = [
      summary,
      ...current.where((item) => item.id != summary.id),
    ].take(maxItems).toList();
    await _save(key, updated);
  }

  Future<List<TitleSummary>> getRecentMovies() => _load(_moviesKey);

  Future<List<TitleSummary>> getRecentSeries() => _load(_seriesKey);

  Future<List<TitleSummary>> _load(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TitleSummary.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, List<TitleSummary> items) async {
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await _prefs.setString(key, encoded);
  }
}
