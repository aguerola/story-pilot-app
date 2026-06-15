import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/media_type.dart';
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
}
