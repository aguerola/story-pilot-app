import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthLinkSent extends AuthState {
  const AuthLinkSent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthCompletingLink extends AuthState {
  const AuthCompletingLink();
}
