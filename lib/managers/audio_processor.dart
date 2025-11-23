import '../models/audio_file.dart';

/// Callback for processing progress updates
typedef ProgressCallback = void Function(double progress);

/// Result of audio processing
class ProcessingResult {
  final String instrumentalPath;
  final Duration processingTime;

  const ProcessingResult({
    required this.instrumentalPath,
    required this.processingTime,
  });
}

/// Abstract interface for audio processing with AI model
abstract class AudioProcessor {
  /// Initialize the processor and load the AI model
  /// Returns true if initialization successful
  /// Throws VocalRemoverError if model loading fails
  Future<bool> initialize();

  /// Process an audio file to remove vocals
  /// Returns path to the processed instrumental file
  /// Calls progressCallback with values from 0.0 to 1.0
  /// Throws VocalRemoverError if processing fails
  Future<ProcessingResult> processAudio(
    AudioFile audioFile, {
    ProgressCallback? onProgress,
  });

  /// Cancel ongoing processing
  Future<void> cancelProcessing();

  /// Check if processor is currently processing
  bool get isProcessing;

  /// Check if processor is initialized
  bool get isInitialized;

  /// Clean up resources
  Future<void> dispose();
}
