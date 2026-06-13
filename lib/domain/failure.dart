import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Parse error']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

final class QuotaFailure extends Failure {
  const QuotaFailure(
    super.message, {
    this.retryAfterSeconds,
  });

  final int? retryAfterSeconds;

  @override
  List<Object?> get props => [message, retryAfterSeconds];
}
