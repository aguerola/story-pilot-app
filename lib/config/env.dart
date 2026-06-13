class Env {
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const openSubtitlesApiKey = String.fromEnvironment('OPENSUBTITLES_API_KEY');
  static const useFirebaseAi = bool.fromEnvironment('USE_FIREBASE_AI');
  static const corsProxy = String.fromEnvironment(
    'CORS_PROXY',
    defaultValue: '',
  );

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const openSubtitlesBaseUrl = 'https://api.opensubtitles.com/api/v1';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String wrapUrl(String url) {
    if (corsProxy.isEmpty) return url;
    final proxy = corsProxy.endsWith('/') ? corsProxy : '$corsProxy/';
    return '$proxy$url';
  }

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;
  static bool get hasOpenSubtitlesKey => openSubtitlesApiKey.isNotEmpty;
}
