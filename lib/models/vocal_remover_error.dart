/// Types of errors that can occur in the app
enum ErrorType {
  unsupportedFormat,
  drmProtected,
  processingFailed,
  modelLoadFailed,
  cacheError,
  fileNotFound,
  insufficientStorage,
  networkError,
  unknown,
}

/// Custom exception for vocal remover errors
class VocalRemoverError implements Exception {
  final ErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const VocalRemoverError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// Create error for unsupported file format
  factory VocalRemoverError.unsupportedFormat(String format) {
    return VocalRemoverError(
      type: ErrorType.unsupportedFormat,
      message: 'File format "$format" is not supported. '
          'Please use MP3, WAV, M4A, or FLAC files.',
    );
  }

  /// Create error for DRM-protected files
  factory VocalRemoverError.drmProtected() {
    return const VocalRemoverError(
      type: ErrorType.drmProtected,
      message: 'This file is DRM-protected and cannot be processed. '
          'Please use DRM-free audio files.',
    );
  }

  /// Create error for processing failures
  factory VocalRemoverError.processingFailed(String reason,
      [dynamic error, StackTrace? stackTrace]) {
    return VocalRemoverError(
      type: ErrorType.processingFailed,
      message: 'Audio processing failed: $reason',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Create error for model loading failures
  factory VocalRemoverError.modelLoadFailed(dynamic error,
      [StackTrace? stackTrace]) {
    return VocalRemoverError(
      type: ErrorType.modelLoadFailed,
      message: 'Failed to load AI model. Please restart the app.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Create error for cache-related issues
  factory VocalRemoverError.cacheError(String reason,
      [dynamic error, StackTrace? stackTrace]) {
    return VocalRemoverError(
      type: ErrorType.cacheError,
      message: 'Cache error: $reason',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Create error for file not found
  factory VocalRemoverError.fileNotFound(String path) {
    return VocalRemoverError(
      type: ErrorType.fileNotFound,
      message: 'File not found: $path',
    );
  }

  /// Create error for insufficient storage
  factory VocalRemoverError.insufficientStorage() {
    return const VocalRemoverError(
      type: ErrorType.insufficientStorage,
      message: 'Insufficient storage space. Please free up some space and try again.',
    );
  }

  /// Create error for network issues
  factory VocalRemoverError.networkError(String reason) {
    return VocalRemoverError(
      type: ErrorType.networkError,
      message: 'Network error: $reason',
    );
  }

  /// Create generic error
  factory VocalRemoverError.unknown(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return VocalRemoverError(
      type: ErrorType.unknown,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case ErrorType.unsupportedFormat:
      case ErrorType.drmProtected:
      case ErrorType.fileNotFound:
      case ErrorType.insufficientStorage:
        return message;
      case ErrorType.processingFailed:
        return 'Failed to remove vocals. Please try again.';
      case ErrorType.modelLoadFailed:
        return 'App initialization failed. Please restart the app.';
      case ErrorType.cacheError:
        return 'Storage error. Try clearing the cache in settings.';
      case ErrorType.networkError:
        return 'Network connection error. Please check your connection.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    return type != ErrorType.modelLoadFailed &&
        type != ErrorType.drmProtected &&
        type != ErrorType.unsupportedFormat;
  }

  @override
  String toString() {
    final buffer = StringBuffer('VocalRemoverError($type): $message');
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}
