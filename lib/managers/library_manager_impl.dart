import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'library_manager.dart';
import '../models/audio_file.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of LibraryManager for cross-platform support
class LibraryManagerImpl implements LibraryManager {
  final List<AudioFile> _files = [];
  final StreamController<List<AudioFile>> _libraryController =
      StreamController<List<AudioFile>>.broadcast();

  static const List<String> _supportedFormats = ['mp3', 'wav', 'm4a', 'flac'];

  @override
  Future<List<AudioFile>> importFiles() async {
    try {
      // Use file_picker for cross-platform file selection
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedFormats,
        allowMultiple: true,
        withData: kIsWeb, // Load data for web platform
      );

      if (result == null) {
        return [];
      }

      final importedFiles = <AudioFile>[];

      for (final platformFile in result.files) {
        try {
          final audioFile = await _processFile(platformFile);
          if (audioFile != null) {
            _files.add(audioFile);
            importedFiles.add(audioFile);
          }
        } catch (e) {
          // Skip files that fail to import
          debugPrint('Failed to import file: ${platformFile.name}, error: $e');
        }
      }

      _libraryController.add(List.from(_files));
      return importedFiles;
    } catch (e, stackTrace) {
      throw VocalRemoverError.unknown(
        'Failed to import files',
        e,
        stackTrace,
      );
    }
  }

  Future<AudioFile?> _processFile(PlatformFile platformFile) async {
    // Validate format
    final extension = platformFile.extension?.toLowerCase();
    if (extension == null || !_supportedFormats.contains(extension)) {
      throw VocalRemoverError.unsupportedFormat(extension ?? 'unknown');
    }

    // Generate unique ID from file path/name
    final id = _generateFileId(platformFile);

    // Check for duplicates
    if (_files.any((f) => f.id == id)) {
      return null; // Skip duplicate
    }

    // Extract metadata
    final metadata = await _extractMetadata(platformFile);

    // Detect DRM
    final isDRMProtected = await _detectDRM(platformFile);

    if (isDRMProtected) {
      throw VocalRemoverError.drmProtected();
    }

    return AudioFile(
      id: id,
      path: platformFile.path ?? platformFile.name,
      title: metadata['title'] ?? _getFileNameWithoutExtension(platformFile.name),
      artist: metadata['artist'] ?? 'Unknown Artist',
      album: metadata['album'] ?? 'Unknown Album',
      duration: metadata['duration'] ?? Duration.zero,
      format: extension,
      isDRMProtected: isDRMProtected,
      albumArtwork: metadata['artwork'],
    );
  }

  String _generateFileId(PlatformFile file) {
    final path = file.path ?? file.name;
    final bytes = utf8.encode(path);
    return sha256.convert(bytes).toString();
  }

  String _getFileNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
  }

  Future<Map<String, dynamic>> _extractMetadata(PlatformFile file) async {
    try {
      if (kIsWeb) {
        // Web: Use basic extraction from filename
        return {
          'title': _getFileNameWithoutExtension(file.name),
          'artist': null,
          'album': null,
          'duration': null,
          'artwork': null,
        };
      } else {
        // Mobile: Use flutter_media_metadata
        if (file.path == null) {
          return {};
        }

        final metadata = await MetadataRetriever.fromFile(File(file.path!));

        return {
          'title': metadata.trackName,
          'artist': metadata.trackArtistNames?.isNotEmpty == true
              ? metadata.trackArtistNames!.join(', ')
              : null,
          'album': metadata.albumName,
          'duration': metadata.trackDuration != null
              ? Duration(milliseconds: metadata.trackDuration!)
              : null,
          'artwork': metadata.albumArt,
        };
      }
    } catch (e) {
      debugPrint('Failed to extract metadata: $e');
      return {};
    }
  }

  Future<bool> _detectDRM(PlatformFile file) async {
    try {
      if (kIsWeb) {
        // Web: Basic check - try to verify file is accessible
        // More sophisticated DRM detection would require decoding attempt
        return false; // Simplified for now
      } else {
        // Mobile: Try to read file to detect DRM
        if (file.path == null) return false;

        final fileHandle = File(file.path!);
        if (!await fileHandle.exists()) {
          throw VocalRemoverError.fileNotFound(file.path!);
        }

        // Attempt to read first few bytes
        // DRM-protected files typically fail to read or decode
        try {
          await fileHandle.open(mode: FileMode.read);
          return false; // File is readable
        } catch (e) {
          return true; // File might be DRM-protected
        }
      }
    } catch (e) {
      debugPrint('DRM detection error: $e');
      return false; // Assume not protected on error
    }
  }

  @override
  Future<List<AudioFile>> scanDeviceFiles() async {
    if (kIsWeb) {
      // Web doesn't support device scanning
      return [];
    }

    // Platform-specific implementation would use platform channels
    // For now, return empty list - full implementation requires native code
    return [];
  }

  @override
  Future<List<AudioFile>> getAllFiles() async {
    return List.from(_files);
  }

  @override
  Future<AudioFile?> getFileById(String id) async {
    try {
      return _files.firstWhere((file) => file.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AudioFile>> searchFiles(String query) async {
    final lowerQuery = query.toLowerCase();
    return _files.where((file) {
      return file.title.toLowerCase().contains(lowerQuery) ||
          file.artist.toLowerCase().contains(lowerQuery) ||
          file.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<void> removeFile(String id) async {
    _files.removeWhere((file) => file.id == id);
    _libraryController.add(List.from(_files));
  }

  @override
  Future<void> updateFile(AudioFile file) async {
    final index = _files.indexWhere((f) => f.id == file.id);
    if (index >= 0) {
      _files[index] = file;
      _libraryController.add(List.from(_files));
    }
  }

  @override
  Future<void> clearLibrary() async {
    _files.clear();
    _libraryController.add([]);
  }

  @override
  Stream<List<AudioFile>> get libraryStream => _libraryController.stream;

  void dispose() {
    _libraryController.close();
  }
}
