import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/result.dart';

class CachedTitleDetail {
  const CachedTitleDetail({required this.data, required this.cachedAt});

  final TitleDetail data;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(hours: 24);
}

class LocalCacheService {
  LocalCacheService(this._prefs);

  final SharedPreferences _prefs;

  static String subtitleLastKey(int tmdbId) => 'subtitle_last_$tmdbId';

  Future<Directory> _cacheDir() async {
    if (kIsWeb) {
      throw UnsupportedError('LocalCacheService is not supported on web');
    }
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/scene_context_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String _titleKey(int id, MediaType type) => 'title_${type.name}_$id.json';

  String _subtitleKey(int tmdbId, String lang, String fileId) =>
      'sub_${tmdbId}_${lang}_$fileId.json';

  String _subtitlePrefsKey(int tmdbId, String lang, String fileId) =>
      'sub_${tmdbId}_${lang}_$fileId';

  Future<CachedTitleDetail?> getTitle(int id, MediaType type) async {
    if (kIsWeb) return null;
    try {
      final file = File('${(await _cacheDir()).path}/${_titleKey(id, type)}');
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CachedTitleDetail(
        data: TitleDetail.fromJson(json),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Result<void>> saveTitle(
    int id,
    MediaType type,
    TitleDetail detail,
  ) async {
    if (kIsWeb) return const Success(null);
    try {
      final file = File('${(await _cacheDir()).path}/${_titleKey(id, type)}');
      await file.writeAsString(jsonEncode(detail.toJson()));
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  Future<SubtitleDocument?> getLatestSubtitleForTitle(int tmdbId) async {
    final meta = _prefs.getString(subtitleLastKey(tmdbId));
    if (meta == null) return null;
    final sep = meta.indexOf('|');
    if (sep <= 0) return null;
    return getSubtitle(
      tmdbId,
      meta.substring(0, sep),
      meta.substring(sep + 1),
    );
  }

  Future<SubtitleDocument?> getSubtitle(
    int tmdbId,
    String lang,
    String fileId,
  ) async {
    if (kIsWeb) {
      final raw = _prefs.getString(_subtitlePrefsKey(tmdbId, lang, fileId));
      if (raw == null) return null;
      try {
        return SubtitleDocument.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }
    try {
      final file = File(
        '${(await _cacheDir()).path}/${_subtitleKey(tmdbId, lang, fileId)}',
      );
      if (!await file.exists()) return null;
      return SubtitleDocument.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Result<void>> saveSubtitle(SubtitleDocument document) async {
    final encoded = jsonEncode(document.toJson());
    final meta = '${document.language}|${document.fileId}';

    if (kIsWeb) {
      try {
        await _prefs.setString(
          _subtitlePrefsKey(
            document.titleId,
            document.language,
            document.fileId,
          ),
          encoded,
        );
        await _prefs.setString(subtitleLastKey(document.titleId), meta);
        return const Success(null);
      } catch (e) {
        return Error(CacheFailure(e.toString()));
      }
    }
    try {
      final file = File(
        '${(await _cacheDir()).path}/${_subtitleKey(document.titleId, document.language, document.fileId)}',
      );
      await file.writeAsString(encoded);
      await _prefs.setString(subtitleLastKey(document.titleId), meta);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }
}
