import '../models/cache_entry.dart';

/// Abstract interface for managing processed audio cache with LRU eviction
abstract class CacheManager {
  /// Initialize cache and database
  Future<void> initialize();

  /// Store processed audio in cache
  /// Returns CacheEntry with metadata
  /// Throws VocalRemoverError if storage fails
  Future<CacheEntry> storeInCache({
    required String fileHash,
    required String instrumentalPath,
    required String originalPath,
  });

  /// Retrieve cached instrumental path by file hash
  /// Returns null if not cached
  /// Updates lastPlayed timestamp on access
  Future<String?> getCachedInstrumental(String fileHash);

  /// Check if file is cached
  Future<bool> isCached(String fileHash);

  /// Get cache entry by file hash
  Future<CacheEntry?> getCacheEntry(String fileHash);

  /// Get all cache entries
  Future<List<CacheEntry>> getAllEntries();

  /// Get total cache size in bytes
  Future<int> getCacheSize();

  /// Trigger LRU eviction
  /// Removes entries older than 30 days
  /// Evicts least recently used until size < maxSize
  /// Returns number of entries evicted
  Future<int> evictCache({int maxSizeBytes = 1073741824}); // 1GB default

  /// Clear all cache
  Future<void> clearCache();

  /// Remove specific cache entry
  Future<void> removeCacheEntry(String fileHash);

  /// Update last played timestamp
  Future<void> updateLastPlayed(String fileHash);

  /// Clean up resources
  Future<void> dispose();
}
