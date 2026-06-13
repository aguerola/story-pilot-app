import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/data/services/auth_service.dart';
import 'package:storypilot/ui/auth/bloc/auth_event.dart';
import 'package:storypilot/ui/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authService) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthEmailSubmitted>(_onEmailSubmitted);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
  }

  final AuthService _authService;
  StreamSubscription<dynamic>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      add(AuthUserChanged(user?.email));
    });

    final link = Uri.base.toString();
    if (_authService.isSignInWithEmailLink(link)) {
      emit(const AuthCompletingLink());
      final email = _authService.pendingEmail;
      if (email == null || email.isEmpty) {
        emit(
          const AuthFailure(
            'No se encontró el email pendiente. Solicita un nuevo enlace.',
          ),
        );
        return;
      }
      try {
        await _authService.completeSignInWithEmailLink(email, link);
      } on Exception catch (error) {
        emit(AuthFailure(error.toString()));
      }
      return;
    }

    final user = _authService.currentUser;
    if (user?.email != null) {
      emit(AuthAuthenticated(user!.email!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final email = event.email;
    if (email != null) {
      emit(AuthAuthenticated(email));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onEmailSubmitted(
    AuthEmailSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(const AuthFailure('Introduce un email válido.'));
      return;
    }
    try {
      await _authService.sendSignInLink(email);
      emit(AuthLinkSent(email));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
