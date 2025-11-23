import 'dart:typed_data';

/// Represents an audio file in the library
class AudioFile {
  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String format;
  final bool isDRMProtected;
  final Uint8List? albumArtwork;

  const AudioFile({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.format,
    required this.isDRMProtected,
    this.albumArtwork,
  });

  /// Create AudioFile from JSON
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as String,
      path: json['path'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      format: json['format'] as String,
      isDRMProtected: json['isDRMProtected'] as bool,
      albumArtwork: json['albumArtwork'] != null
          ? Uint8List.fromList(List<int>.from(json['albumArtwork']))
          : null,
    );
  }

  /// Convert AudioFile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inMilliseconds,
      'format': format,
      'isDRMProtected': isDRMProtected,
      'albumArtwork': albumArtwork?.toList(),
    };
  }

  /// Create a copy with optional field updates
  AudioFile copyWith({
    String? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? format,
    bool? isDRMProtected,
    Uint8List? albumArtwork,
  }) {
    return AudioFile(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      format: format ?? this.format,
      isDRMProtected: isDRMProtected ?? this.isDRMProtected,
      albumArtwork: albumArtwork ?? this.albumArtwork,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path;

  @override
  int get hashCode => id.hashCode ^ path.hashCode;

  @override
  String toString() => 'AudioFile(id: $id, title: $title, artist: $artist)';
}
