import 'package:storypilot/domain/failure.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Error() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Error(:final failure) => failure,
      };
}
