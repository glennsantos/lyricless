import '../models/audio_file.dart';
import '../models/processing_task.dart';

/// Repeat mode for playback queue
enum RepeatMode {
  off,
  one,
  all,
}

/// Abstract interface for managing playback queue with look-ahead processing
abstract class QueueManager {
  /// Get current queue
  List<AudioFile> get queue;

  /// Get current track
  AudioFile? get currentTrack;

  /// Get next track
  AudioFile? get nextTrack;

  /// Get repeat mode
  RepeatMode get repeatMode;

  /// Get shuffle enabled state
  bool get shuffleEnabled;

  /// Add files to queue
  void enqueueFiles(List<AudioFile> files);

  /// Add single file to queue
  void enqueue(AudioFile file);

  /// Skip to next track
  /// Cancels processing of previous next track
  /// Triggers look-ahead for new next track
  void skipNext();

  /// Skip to previous track
  void skipPrevious();

  /// Jump to specific track in queue
  void jumpToTrack(int index);

  /// Remove track from queue
  void removeFromQueue(int index);

  /// Reorder queue (drag and drop support)
  void reorderQueue(int oldIndex, int newIndex);

  /// Clear the queue
  void clearQueue();

  /// Set repeat mode
  void setRepeatMode(RepeatMode mode);

  /// Toggle shuffle
  void toggleShuffle();

  /// Get current processing task for next track (if any)
  ProcessingTask? get currentProcessingTask;

  /// Stream of queue updates
  Stream<List<AudioFile>> get queueStream;

  /// Stream of current track updates
  Stream<AudioFile?> get currentTrackStream;

  /// Stream of processing task updates
  Stream<ProcessingTask?> get processingTaskStream;
}
