import '../models/audio_file.dart';

/// Abstract interface for managing the audio library
abstract class LibraryManager {
  /// Import audio files from user selection
  /// Returns list of successfully imported files
  /// Throws VocalRemoverError if import fails
  Future<List<AudioFile>> importFiles();

  /// Scan device for audio files (mobile only)
  /// Returns list of discovered audio files
  /// Filters out DRM-protected files
  Future<List<AudioFile>> scanDeviceFiles();

  /// Get all files in the library
  Future<List<AudioFile>> getAllFiles();

  /// Get a specific file by ID
  Future<AudioFile?> getFileById(String id);

  /// Search files by query (title, artist, album)
  Future<List<AudioFile>> searchFiles(String query);

  /// Remove a file from the library
  Future<void> removeFile(String id);

  /// Update file metadata
  Future<void> updateFile(AudioFile file);

  /// Clear all files from library
  Future<void> clearLibrary();

  /// Stream of library updates
  Stream<List<AudioFile>> get libraryStream;
}
