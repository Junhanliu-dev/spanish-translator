import 'app_exception.dart';

/// Maps exceptions to user-friendly messages.
String mapErrorToMessage(Object error) {
  if (error is NetworkException) {
    return 'No internet connection. Please check your network.';
  }
  if (error is ApiKeyException) {
    return 'Your API key is invalid or expired. '
        'Please update it in Settings.';
  }
  if (error is RateLimitException) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (error is TimeoutException) {
    return 'Request timed out. Please try again.';
  }
  if (error is ApiException) {
    return 'Translation failed. Please try again.';
  }
  if (error is StorageException) {
    return 'Could not save data. Please try again.';
  }
  if (error is PermissionException) {
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}
