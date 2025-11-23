import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'queue_manager.dart';
import 'audio_processor.dart';
import 'cache_manager.dart';
import '../models/audio_file.dart';
import '../models/processing_task.dart';

/// Implementation of QueueManager with look-ahead processing
class QueueManagerImpl implements QueueManager {
  final AudioProcessor _audioProcessor;
  final CacheManager _cacheManager;

  List<AudioFile> _queue = [];
  List<AudioFile> _originalQueue = [];
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffleEnabled = false;
  ProcessingTask? _currentProcessingTask;

  final StreamController<List<AudioFile>> _queueController =
      StreamController<List<AudioFile>>.broadcast();
  final StreamController<AudioFile?> _currentTrackController =
      StreamController<AudioFile?>.broadcast();
  final StreamController<ProcessingTask?> _processingTaskController =
      StreamController<ProcessingTask?>.broadcast();

  final Random _random = Random();

  QueueManagerImpl({
    required AudioProcessor audioProcessor,
    required CacheManager cacheManager,
  })  : _audioProcessor = audioProcessor,
        _cacheManager = cacheManager;

  @override
  List<AudioFile> get queue => List.from(_queue);

  @override
  AudioFile? get currentTrack {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      return _queue[_currentIndex];
    }
    return null;
  }

  @override
  AudioFile? get nextTrack {
    final nextIndex = _calculateNextIndex();
    if (nextIndex >= 0 && nextIndex < _queue.length) {
      return _queue[nextIndex];
    }
    return null;
  }

  @override
  RepeatMode get repeatMode => _repeatMode;

  @override
  bool get shuffleEnabled => _shuffleEnabled;

  @override
  void enqueueFiles(List<AudioFile> files) {
    _queue.addAll(files);
    _originalQueue = List.from(_queue);

    if (_shuffleEnabled) {
      _shuffleQueue();
    }

    _queueController.add(List.from(_queue));

    // Start playing if queue was empty
    if (_currentIndex == -1 && _queue.isNotEmpty) {
      _currentIndex = 0;
      _currentTrackController.add(currentTrack);
      _triggerLookAheadProcessing();
    }
  }

  @override
  void enqueue(AudioFile file) {
    enqueueFiles([file]);
  }

  @override
  void skipNext() {
    // Cancel current processing task
    if (_currentProcessingTask != null &&
        _currentProcessingTask!.status == TaskStatus.processing) {
      _audioProcessor.cancelProcessing();
      _currentProcessingTask = _currentProcessingTask!.copyWith(
        status: TaskStatus.cancelled,
      );
      _processingTaskController.add(_currentProcessingTask);
    }

    // Move to next track
    _currentIndex = _calculateNextIndex();
    _currentTrackController.add(currentTrack);

    // Trigger look-ahead for new next track
    _triggerLookAheadProcessing();
  }

  @override
  void skipPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _queue.length - 1;
    }

    _currentTrackController.add(currentTrack);
    _triggerLookAheadProcessing();
  }

  @override
  void jumpToTrack(int index) {
    if (index >= 0 && index < _queue.length) {
      // Cancel current processing
      if (_currentProcessingTask != null) {
        _audioProcessor.cancelProcessing();
      }

      _currentIndex = index;
      _currentTrackController.add(currentTrack);
      _triggerLookAheadProcessing();
    }
  }

  @override
  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);

      // Adjust current index if necessary
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        _currentTrackController.add(currentTrack);
        _triggerLookAheadProcessing();
      }

      _queueController.add(List.from(_queue));
    }
  }

  @override
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return;
    }

    final file = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, file);

    // Adjust current index
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    _queueController.add(List.from(_queue));
    _triggerLookAheadProcessing();
  }

  @override
  void clearQueue() {
    // Cancel processing
    if (_currentProcessingTask != null) {
      _audioProcessor.cancelProcessing();
    }

    _queue.clear();
    _originalQueue.clear();
    _currentIndex = -1;
    _currentProcessingTask = null;

    _queueController.add([]);
    _currentTrackController.add(null);
    _processingTaskController.add(null);
  }

  @override
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  @override
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;

    if (_shuffleEnabled) {
      _shuffleQueue();
    } else {
      // Restore original order
      _queue = List.from(_originalQueue);
      // Find current track in restored queue
      if (currentTrack != null) {
        _currentIndex = _queue.indexWhere((f) => f.id == currentTrack!.id);
      }
    }

    _queueController.add(List.from(_queue));
  }

  void _shuffleQueue() {
    final current = currentTrack;
    _queue.shuffle(_random);

    // Ensure current track stays at current position
    if (current != null) {
      final currentInShuffled = _queue.indexWhere((f) => f.id == current.id);
      if (currentInShuffled != _currentIndex && currentInShuffled >= 0) {
        // Swap to keep current track at current index
        final temp = _queue[_currentIndex];
        _queue[_currentIndex] = _queue[currentInShuffled];
        _queue[currentInShuffled] = temp;
      }
    }
  }

  int _calculateNextIndex() {
    if (_queue.isEmpty) return -1;

    switch (_repeatMode) {
      case RepeatMode.one:
        return _currentIndex;

      case RepeatMode.all:
        return (_currentIndex + 1) % _queue.length;

      case RepeatMode.off:
        final next = _currentIndex + 1;
        return next < _queue.length ? next : -1;
    }
  }

  Future<void> _triggerLookAheadProcessing() async {
    try {
      final next = nextTrack;
      if (next == null) {
        _currentProcessingTask = null;
        _processingTaskController.add(null);
        return;
      }

      // Check if already cached
      final fileHash = CacheManagerImpl.generateFileHash(next.path);
      final isCached = await _cacheManager.isCached(fileHash);

      if (isCached) {
        _currentProcessingTask = null;
        _processingTaskController.add(null);
        return;
      }

      // Start background processing
      _currentProcessingTask = ProcessingTask(
        id: '${next.id}_${DateTime.now().millisecondsSinceEpoch}',
        audioFile: next,
        status: TaskStatus.queued,
        progress: 0.0,
        startTime: DateTime.now(),
      );
      _processingTaskController.add(_currentProcessingTask);

      // Process in background (isolate or Web Worker)
      await _processInBackground(next);
    } catch (e) {
      debugPrint('Look-ahead processing error: $e');
      _currentProcessingTask = _currentProcessingTask?.copyWith(
        status: TaskStatus.failed,
        errorMessage: e.toString(),
      );
      _processingTaskController.add(_currentProcessingTask);
    }
  }

  Future<void> _processInBackground(AudioFile file) async {
    try {
      _currentProcessingTask = _currentProcessingTask!.copyWith(
        status: TaskStatus.processing,
      );
      _processingTaskController.add(_currentProcessingTask);

      final result = await _audioProcessor.processAudio(
        file,
        onProgress: (progress) {
          _currentProcessingTask = _currentProcessingTask!.copyWith(
            progress: progress,
          );
          _processingTaskController.add(_currentProcessingTask);
        },
      );

      // Store in cache
      final fileHash = CacheManagerImpl.generateFileHash(file.path);
      await _cacheManager.storeInCache(
        fileHash: fileHash,
        instrumentalPath: result.instrumentalPath,
        originalPath: file.path,
      );

      _currentProcessingTask = _currentProcessingTask!.copyWith(
        status: TaskStatus.completed,
        progress: 1.0,
        completionTime: DateTime.now(),
      );
      _processingTaskController.add(_currentProcessingTask);
    } catch (e) {
      _currentProcessingTask = _currentProcessingTask?.copyWith(
        status: TaskStatus.failed,
        errorMessage: e.toString(),
      );
      _processingTaskController.add(_currentProcessingTask);
    }
  }

  @override
  ProcessingTask? get currentProcessingTask => _currentProcessingTask;

  @override
  Stream<List<AudioFile>> get queueStream => _queueController.stream;

  @override
  Stream<AudioFile?> get currentTrackStream => _currentTrackController.stream;

  @override
  Stream<ProcessingTask?> get processingTaskStream =>
      _processingTaskController.stream;

  void dispose() {
    _queueController.close();
    _currentTrackController.close();
    _processingTaskController.close();
  }
}
