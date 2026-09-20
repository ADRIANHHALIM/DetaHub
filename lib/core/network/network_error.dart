// lib/core/network/network_error.dart
//
// Sealed class hierarchy for typed network errors.
// Avoids leaking Dio-specific exceptions into the feature layer.
// All service methods return Result<T, NetworkError> — never throw.

/// Typed domain errors from network operations.
///
/// Use exhaustive pattern matching on the call site:
/// ```dart
/// switch (error) {
///   case TimeoutError() => showMessage('Device not responding');
///   case UnreachableError() => showMessage('Cannot reach device');
///   case ParseError()   => showMessage('Unexpected response format');
///   case NotFoundError()   => showMessage('Endpoint not found');
/// }
/// ```
sealed class NetworkError {
  const NetworkError();
}

/// Connection or receive timeout — device is unreachable or too slow.
class TimeoutError extends NetworkError {
  final String message;
  const TimeoutError([this.message = 'Request timed out']);
  @override
  String toString() => 'TimeoutError: $message';
}

/// HTTP 404 — endpoint exists on device but path is wrong.
class NotFoundError extends NetworkError {
  final String path;
  const NotFoundError(this.path);
  @override
  String toString() => 'NotFoundError: $path';
}

/// Connection refused or network unreachable — device offline or wrong IP.
class UnreachableError extends NetworkError {
  final String url;
  const UnreachableError(this.url);
  @override
  String toString() => 'UnreachableError: $url';
}

/// Response body could not be parsed — firmware mismatch or corrupt response.
class ParseError extends NetworkError {
  final String detail;
  const ParseError(this.detail);
  @override
  String toString() => 'ParseError: $detail';
}

/// Any other unexpected HTTP or network error.
class UnknownNetworkError extends NetworkError {
  final Object cause;
  const UnknownNetworkError(this.cause);
  @override
  String toString() => 'UnknownNetworkError: $cause';
}

// ---------------------------------------------------------------------------
// Lightweight Result type (zero external dependencies)
// ---------------------------------------------------------------------------

/// A discriminated union of success [Ok] and failure [Err].
/// Avoids try/catch propagation across the feature layer.
sealed class Result<T, E> {
  const Result();

  /// Returns true if this is an [Ok] result.
  bool get isOk => this is Ok<T, E>;

  /// Returns true if this is an [Err] result.
  bool get isErr => this is Err<T, E>;

  /// Unwraps the success value. Throws if [Err].
  T get value => (this as Ok<T, E>).value;

  /// Unwraps the error. Throws if [Ok].
  E get error => (this as Err<T, E>).error;

  /// Maps the success value with [f], leaving errors untouched.
  Result<U, E> map<U>(U Function(T) f) => switch (this) {
        Ok(:final value) => Ok(f(value)),
        Err(:final error) => Err(error),
      };
}

class Ok<T, E> extends Result<T, E> {
  @override
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  @override
  final E error;
  const Err(this.error);
}
