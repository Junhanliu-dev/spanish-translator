/// Base exception for all app errors.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// A human-readable description of the error.
  final String message;

  /// The underlying cause, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-related errors (no connectivity, DNS failure, etc.).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// OpenAI API errors (non-network).
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode, super.cause});

  /// HTTP status code returned by the API, if available.
  final int? statusCode;
}

/// Invalid or expired API key (HTTP 401).
class ApiKeyException extends ApiException {
  const ApiKeyException(super.message, {super.statusCode, super.cause});
}

/// Rate limit exceeded (HTTP 429).
class RateLimitException extends ApiException {
  const RateLimitException(super.message, {super.statusCode, super.cause});
}

/// API request timeout.
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.cause});
}

/// Storage/database errors.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Permission denied (mic, camera).
class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}
