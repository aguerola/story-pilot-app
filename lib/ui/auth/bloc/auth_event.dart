import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthEmailSubmitted extends AuthEvent {
  const AuthEmailSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.email);

  final String? email;

  @override
  List<Object?> get props => [email];
}
