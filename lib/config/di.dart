import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/config/env.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/subtitle_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/firebase_ai_ask_service.dart';
import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/local_stub_ask_service.dart';
import 'package:storypilot/data/services/open_subtitles_service.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/data/services/scene_analyzer_service.dart';
import 'package:storypilot/data/services/settings_service.dart';
import 'package:storypilot/data/services/subtitle_parser_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/data/services/tmdb_service.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/search/bloc/search_bloc.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton(
      () => SettingsService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton(
      () => AuthService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton(
      () => UsageLimitService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton(
      () => AuthBloc(getIt<AuthService>())..add(const AuthStarted()),
    )
    ..registerLazySingleton(TitleSessionHolder.new)
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ),
    )
    ..registerLazySingleton(() => TmdbService(getIt<Dio>()))
    ..registerLazySingleton(() => OpenSubtitlesService(getIt<Dio>()))
    ..registerLazySingleton(SubtitleParserService.new)
    ..registerLazySingleton(
      () => LocalCacheService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton(SceneAnalyzerService.new)
    ..registerLazySingleton<AskService>(_createAskService)
    ..registerLazySingleton(
      () => TitleRepository(getIt<TmdbService>(), getIt<LocalCacheService>()),
    )
    ..registerLazySingleton(
      () => SubtitleRepository(
        getIt<OpenSubtitlesService>(),
        getIt<SubtitleParserService>(),
        getIt<LocalCacheService>(),
      ),
    )
    ..registerLazySingleton(
      () => SceneRepository(getIt<SceneAnalyzerService>()),
    )
    ..registerLazySingleton(() => AskRepository(getIt<AskService>()))
    ..registerFactory(() => SearchBloc(getIt<TitleRepository>()))
    ..registerFactory(
      () => TitleDetailBloc(
        getIt<TitleRepository>(),
        getIt<TitleSessionHolder>(),
      ),
    )
    ..registerFactory(
      () => SceneBloc(
        getIt<SceneRepository>(),
        getIt<SubtitleRepository>(),
        getIt<TitleSessionHolder>(),
      ),
    )
    ..registerFactory(
      () => AskBloc(
        getIt<AskRepository>(),
        getIt<SettingsService>(),
        getIt<AuthService>(),
        getIt<UsageLimitService>(),
      ),
    );
}

AskService _createAskService() {
  if (Env.useFirebaseAi) {
    return FirebaseAiAskService();
  }
  return LocalStubAskService();
}
