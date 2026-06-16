class Env {
  static const useFunctionsEmulator = bool.fromEnvironment(
    'USE_FUNCTIONS_EMULATOR',
  );

  static const functionsRegion = 'europe-west1';

  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}
