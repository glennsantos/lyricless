import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'cache_manager.dart';
import '../models/cache_entry.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of CacheManager with LRU eviction
class CacheManagerImpl implements CacheManager {
  Database? _database;
  String? _cacheDirectory;

  static const String _tableName = 'cache_entries';
  static const int _maxCacheSizeBytes = 1073741824; // 1GB
  static const int _maxAgedays = 30;

  @override
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web: Use IndexedDB via idb_shim
        _cacheDirectory = 'cache'; // Virtual path for web
        // Web database initialization would go here
        throw UnimplementedError('Web cache not yet fully implemented');
      } else {
        // Mobile: Use SQLite
        final dbPath = await getDatabasesPath();
        _database = await openDatabase(
          '$dbPath/lyricless_cache.db',
          version: 1,
          onCreate: _createDatabase,
        );

        // Set cache directory
        final cacheDir = await getTemporaryDirectory();
        _cacheDirectory = '${cacheDir.path}/processed_audio';

        // Create cache directory if it doesn't exist
        final dir = Directory(_cacheDirectory!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to initialize cache',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        fileHash TEXT PRIMARY KEY,
        instrumentalPath TEXT NOT NULL,
        originalPath TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        lastPlayed INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create index for LRU queries
    await db.execute('''
      CREATE INDEX idx_lastPlayed ON $_tableName(lastPlayed)
    ''');
  }

  @override
  Future<CacheEntry> storeInCache({
    required String fileHash,
    required String instrumentalPath,
    required String originalPath,
  }) async {
    _ensureInitialized();

    try {
      // Get file size
      int fileSize = 0;
      if (!kIsWeb) {
        final file = File(instrumentalPath);
        if (await file.exists()) {
          fileSize = await file.length();
        }
      }

      final now = DateTime.now();
      final entry = CacheEntry(
        fileHash: fileHash,
        instrumentalPath: instrumentalPath,
        originalPath: originalPath,
        fileSize: fileSize,
        lastPlayed: now,
        createdAt: now,
      );

      // Store in database
      await _database!.insert(
        _tableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Check if eviction needed
      final totalSize = await getCacheSize();
      if (totalSize > _maxCacheSizeBytes) {
        await evictCache();
      }

      return entry;
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to store in cache',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<String?> getCachedInstrumental(String fileHash) async {
    _ensureInitialized();

    try {
      final results = await _database!.query(
        _tableName,
        where: 'fileHash = ?',
        whereArgs: [fileHash],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      final entry = CacheEntry.fromMap(results.first);

      // Verify file still exists
      if (!kIsWeb) {
        final file = File(entry.instrumentalPath);
        if (!await file.exists()) {
          // File was deleted, remove from cache
          await removeCacheEntry(fileHash);
          return null;
        }
      }

      // Update last played
      await updateLastPlayed(fileHash);

      return entry.instrumentalPath;
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to retrieve from cache',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<bool> isCached(String fileHash) async {
    final path = await getCachedInstrumental(fileHash);
    return path != null;
  }

  @override
  Future<CacheEntry?> getCacheEntry(String fileHash) async {
    _ensureInitialized();

    try {
      final results = await _database!.query(
        _tableName,
        where: 'fileHash = ?',
        whereArgs: [fileHash],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return CacheEntry.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<CacheEntry>> getAllEntries() async {
    _ensureInitialized();

    try {
      final results = await _database!.query(_tableName);
      return results.map((row) => CacheEntry.fromMap(row)).toList();
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to get all entries',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<int> getCacheSize() async {
    _ensureInitialized();

    try {
      final entries = await getAllEntries();
      int totalSize = 0;

      for (final entry in entries) {
        if (!kIsWeb) {
          final file = File(entry.instrumentalPath);
          if (await file.exists()) {
            totalSize += await file.length();
          }
        } else {
          totalSize += entry.fileSize;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> evictCache({int maxSizeBytes = _maxCacheSizeBytes}) async {
    _ensureInitialized();

    try {
      int evictedCount = 0;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: _maxAgedays));

      // Step 1: Remove entries older than 30 days
      final oldEntries = await _database!.query(
        _tableName,
        where: 'createdAt < ?',
        whereArgs: [thirtyDaysAgo.millisecondsSinceEpoch],
      );

      for (final row in oldEntries) {
        final entry = CacheEntry.fromMap(row);
        await _deleteEntry(entry);
        evictedCount++;
      }

      // Step 2: Check if we're still over limit
      int currentSize = await getCacheSize();

      if (currentSize <= maxSizeBytes) {
        return evictedCount;
      }

      // Step 3: Remove least recently used until under limit
      final lruEntries = await _database!.query(
        _tableName,
        orderBy: 'lastPlayed ASC',
      );

      for (final row in lruEntries) {
        if (currentSize <= maxSizeBytes) {
          break;
        }

        final entry = CacheEntry.fromMap(row);
        await _deleteEntry(entry);
        currentSize -= entry.fileSize;
        evictedCount++;
      }

      return evictedCount;
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to evict cache',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _deleteEntry(CacheEntry entry) async {
    // Delete file
    if (!kIsWeb) {
      final file = File(entry.instrumentalPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete database entry
    await _database!.delete(
      _tableName,
      where: 'fileHash = ?',
      whereArgs: [entry.fileHash],
    );
  }

  @override
  Future<void> clearCache() async {
    _ensureInitialized();

    try {
      // Get all entries
      final entries = await getAllEntries();

      // Delete all files
      for (final entry in entries) {
        await _deleteEntry(entry);
      }
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to clear cache',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> removeCacheEntry(String fileHash) async {
    _ensureInitialized();

    try {
      final entry = await getCacheEntry(fileHash);
      if (entry != null) {
        await _deleteEntry(entry);
      }
    } catch (e, stackTrace) {
      throw VocalRemoverError.cacheError(
        'Failed to remove cache entry',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> updateLastPlayed(String fileHash) async {
    _ensureInitialized();

    try {
      await _database!.update(
        _tableName,
        {'lastPlayed': DateTime.now().millisecondsSinceEpoch},
        where: 'fileHash = ?',
        whereArgs: [fileHash],
      );
    } catch (e) {
      // Silently fail - not critical
      debugPrint('Failed to update lastPlayed: $e');
    }
  }

  void _ensureInitialized() {
    if (_database == null && !kIsWeb) {
      throw VocalRemoverError.cacheError('Cache manager not initialized');
    }
  }

  @override
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }

  /// Generate SHA256 hash for file content
  static String generateFileHash(String filePath) {
    final bytes = utf8.encode(filePath);
    return sha256.convert(bytes).toString();
  }
}
