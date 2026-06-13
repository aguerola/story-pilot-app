import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // ignore: avoid_print
    print('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
