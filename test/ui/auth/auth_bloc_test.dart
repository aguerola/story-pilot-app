import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_event.dart';
import 'package:storypilot/ui/auth/bloc/auth_state.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;
  late AuthBloc bloc;

  setUp(() {
    authService = MockAuthService();
    when(() => authService.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => authService.currentUser).thenReturn(null);
    when(() => authService.isSignInWithEmailLink(any())).thenReturn(false);
    when(() => authService.sendSignInLink(any())).thenAnswer((_) async {});
    when(() => authService.signOut()).thenAnswer((_) async {});
  });

  tearDown(() => bloc.close());

  blocTest<AuthBloc, AuthState>(
    'emits AuthUnauthenticated when no user on start',
    build: () {
      bloc = AuthBloc(authService);
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthLinkSent after sending sign-in link',
    build: () {
      bloc = AuthBloc(authService);
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthEmailSubmitted('user@example.com')),
    expect: () => [const AuthLinkSent('user@example.com')],
    verify: (_) {
      verify(() => authService.sendSignInLink('user@example.com')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure for empty email',
    build: () {
      bloc = AuthBloc(authService);
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthEmailSubmitted('  ')),
    expect: () => [const AuthFailure('Introduce un email válido.')],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthUnauthenticated after sign out',
    build: () {
      bloc = AuthBloc(authService);
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => [const AuthUnauthenticated()],
    verify: (_) {
      verify(() => authService.signOut()).called(1);
    },
  );
}
