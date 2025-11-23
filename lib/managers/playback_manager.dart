import '../models/audio_file.dart';

/// Playback state
enum PlaybackState {
  stopped,
  playing,
  paused,
  buffering,
  processing,
}

/// Playback position information
class PlaybackPosition {
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  const PlaybackPosition({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
}

/// Abstract interface for managing audio playback
abstract class PlaybackManager {
  /// Initialize the audio player
  Future<void> initialize();

  /// Play an audio file
  /// If file is not cached, triggers processing first
  /// Throws VocalRemoverError if playback fails
  Future<void> play(AudioFile file);

  /// Resume playback
  Future<void> resume();

  /// Pause playback
  Future<void> pause();

  /// Stop playback
  Future<void> stop();

  /// Seek to position
  Future<void> seek(Duration position);

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Get current volume
  double get volume;

  /// Get current playback state
  PlaybackState get state;

  /// Get currently playing file
  AudioFile? get currentFile;

  /// Get current playback position
  PlaybackPosition get position;

  /// Stream of playback state changes
  Stream<PlaybackState> get stateStream;

  /// Stream of playback position updates
  Stream<PlaybackPosition> get positionStream;

  /// Stream of playback completion events
  Stream<void> get completionStream;

  /// Clean up resources
  Future<void> dispose();
}
