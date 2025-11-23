/// Represents a cached processed audio file
class CacheEntry {
  final String fileHash;
  final String instrumentalPath;
  final String originalPath;
  final int fileSize;
  final DateTime lastPlayed;
  final DateTime createdAt;

  const CacheEntry({
    required this.fileHash,
    required this.instrumentalPath,
    required this.originalPath,
    required this.fileSize,
    required this.lastPlayed,
    required this.createdAt,
  });

  /// Create CacheEntry from database row
  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry(
      fileHash: map['fileHash'] as String,
      instrumentalPath: map['instrumentalPath'] as String,
      originalPath: map['originalPath'] as String,
      fileSize: map['fileSize'] as int,
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  /// Convert CacheEntry to database row
  Map<String, dynamic> toMap() {
    return {
      'fileHash': fileHash,
      'instrumentalPath': instrumentalPath,
      'originalPath': originalPath,
      'fileSize': fileSize,
      'lastPlayed': lastPlayed.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with optional field updates
  CacheEntry copyWith({
    String? fileHash,
    String? instrumentalPath,
    String? originalPath,
    int? fileSize,
    DateTime? lastPlayed,
    DateTime? createdAt,
  }) {
    return CacheEntry(
      fileHash: fileHash ?? this.fileHash,
      instrumentalPath: instrumentalPath ?? this.instrumentalPath,
      originalPath: originalPath ?? this.originalPath,
      fileSize: fileSize ?? this.fileSize,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntry &&
          runtimeType == other.runtimeType &&
          fileHash == other.fileHash;

  @override
  int get hashCode => fileHash.hashCode;

  @override
  String toString() =>
      'CacheEntry(fileHash: $fileHash, size: $fileSize bytes, lastPlayed: $lastPlayed)';
}
