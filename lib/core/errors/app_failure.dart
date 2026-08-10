sealed class AppFailure {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message, {super.cause});
}
