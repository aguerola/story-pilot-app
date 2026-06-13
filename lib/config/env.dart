import 'package:flutter/foundation.dart';

class Env {
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const openSubtitlesApiKey = String.fromEnvironment('OPENSUBTITLES_API_KEY');
  static const useFirebaseAi = bool.fromEnvironment('USE_FIREBASE_AI');
  static const corsProxy = String.fromEnvironment(
    'CORS_PROXY',
    defaultValue: '',
  );
  static const useFunctionsEmulator = bool.fromEnvironment(
    'USE_FUNCTIONS_EMULATOR',
  );

  static const functionsRegion = 'europe-west1';

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const openSubtitlesBaseUrl = 'https://api.opensubtitles.com/api/v1';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static const _defaultWebCorsProxy = 'https://corsproxy.io/?';

  static String wrapUrl(String url) {
    if (corsProxy.isEmpty) return url;
    if (corsProxy.contains('url=')) {
      return '$corsProxy${Uri.encodeComponent(url)}';
    }
    final proxy = corsProxy.endsWith('/') ? corsProxy : '$corsProxy/';
    return '$proxy$url';
  }

  /// File hosts (e.g. opensubtitles.com CDN) block browser CORS on web.
  static String wrapCrossOriginFileUrl(String url) {
    if (corsProxy.isNotEmpty) return wrapUrl(url);
    if (kIsWeb) {
      return '$_defaultWebCorsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;
  static bool get hasOpenSubtitlesKey => openSubtitlesApiKey.isNotEmpty;
  static bool get useStoryPilotServer => kIsWeb;
}
