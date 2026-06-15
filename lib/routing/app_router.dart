import 'package:go_router/go_router.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/ui/auth/widgets/login_screen.dart';
import 'package:storypilot/ui/scene/widgets/scene_screen.dart';
import 'package:storypilot/ui/search/widgets/search_screen.dart';
import 'package:storypilot/ui/title_detail/widgets/title_detail_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/title/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final typeName = state.uri.queryParameters['type'] ?? 'movie';
          return TitleDetailScreen(
            id: id,
            mediaType: MediaType.fromTmdb(typeName),
          );
        },
        routes: [
          GoRoute(
            path: 'scene',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final typeName = state.uri.queryParameters['type'] ?? 'movie';
              return SceneScreen(
                id: id,
                mediaType: MediaType.fromTmdb(typeName),
              );
            },
          ),
          GoRoute(
            path: 'ask',
            redirect: (context, state) {
              final id = state.pathParameters['id']!;
              return '/title/$id/scene';
            },
          ),
        ],
      ),
    ],
  );
}
