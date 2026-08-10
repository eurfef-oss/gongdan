import '../errors/app_failure.dart';

sealed class AppResult<T> {
  const AppResult();

  R fold<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) =>
      switch (this) {
        AppSuccess<T>(value: final value) => success(value),
        AppError<T>(failure: final error) => failure(error),
      };
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);
  final T value;
}

final class AppError<T> extends AppResult<T> {
  const AppError(this.failure);
  final AppFailure failure;
}
