import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/data/repositories/scene_repository.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/data/services/browse_history_service.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';
import 'package:storypilot/data/services/ask_service.dart';
import 'package:storypilot/data/services/ask_functions_client.dart';
import 'package:storypilot/data/services/callable_ask_service.dart';
import 'package:storypilot/data/services/local_cache_service.dart';
import 'package:storypilot/data/services/scene_functions_client.dart';
import 'package:storypilot/data/services/tmdb_functions_client.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/data/services/settings_service.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/data/services/tmdb_service.dart';
import 'package:storypilot/ui/home/bloc/home_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_brief_cubit.dart';
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
    ..registerLazySingleton<TmdbFunctionsClient>(
      FirebaseTmdbFunctionsClient.new,
    )
    ..registerLazySingleton<SceneFunctionsClient>(
      FirebaseSceneFunctionsClient.new,
    )
    ..registerLazySingleton(LocalCacheService.new)
    ..registerLazySingleton(
      () => BrowseHistoryService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<AskService>(
      () => CallableAskService(
        client: FirebaseAskFunctionsClient(),
        session: getIt<TitleSessionHolder>(),
      ),
    )
    ..registerLazySingleton(
      () => TitleRepository(
        TmdbService(getIt<TmdbFunctionsClient>()),
        getIt<LocalCacheService>(),
      ),
    )
    ..registerLazySingleton(
      () => SceneRepository(getIt<SceneFunctionsClient>()),
    )
    ..registerLazySingleton(() => AskRepository(getIt<AskService>()))
    ..registerFactory(() => SearchBloc(getIt<TitleRepository>()))
    ..registerFactory(
      () => HomeBloc(
        getIt<TitleRepository>(),
        getIt<BrowseHistoryService>(),
      ),
    )
    ..registerFactory(
      () => TitleDetailBloc(
        getIt<TitleRepository>(),
        getIt<TitleSessionHolder>(),
        getIt<BrowseHistoryService>(),
      ),
    )
    ..registerFactory(
      () => SceneBloc(
        getIt<SceneRepository>(),
        getIt<TitleRepository>(),
        getIt<TitleSessionHolder>(),
      ),
    )
    ..registerFactory(() => SceneBriefCubit(getIt<AskRepository>()))
    ..registerFactory(
      () => AskBloc(
        getIt<AskRepository>(),
        getIt<AuthService>(),
        getIt<UsageLimitService>(),
      ),
    );
}
