import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/app_bloc_observer.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/config/firebase_init.dart';
import 'package:storypilot/routing/app_router.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/core/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
  }
  await configureDependencies();
  await initializeFirebase();
  runApp(const StoryPilotApp());
}

class StoryPilotApp extends StatelessWidget {
  const StoryPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Scene Context',
        theme: AppTheme.light,
        routerConfig: createAppRouter(),
      ),
    );
  }
}
