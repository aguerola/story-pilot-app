class Env {
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const corsProxy = String.fromEnvironment(
    'CORS_PROXY',
    defaultValue: '',
  );
  static const useFunctionsEmulator = bool.fromEnvironment(
    'USE_FUNCTIONS_EMULATOR',
  );

  static const functionsRegion = 'europe-west1';

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String wrapUrl(String url) {
    if (corsProxy.isEmpty) return url;
    if (corsProxy.contains('url=')) {
      return '$corsProxy${Uri.encodeComponent(url)}';
    }
    final proxy = corsProxy.endsWith('/') ? corsProxy : '$corsProxy/';
    return '$proxy$url';
  }

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;
}
