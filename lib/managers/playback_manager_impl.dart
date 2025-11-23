import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'playback_manager.dart';
import 'audio_processor.dart';
import 'cache_manager.dart';
import 'cache_manager_impl.dart';
import '../models/audio_file.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of PlaybackManager using just_audio
class PlaybackManagerImpl implements PlaybackManager {
  final AudioProcessor _audioProcessor;
  final CacheManager _cacheManager;

  late final AudioPlayer _player;
  PlaybackState _state = PlaybackState.stopped;
  AudioFile? _currentFile;
  double _volume = 1.0;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<PlaybackPosition> _positionController =
      StreamController<PlaybackPosition>.broadcast();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

  PlaybackManagerImpl({
    required AudioProcessor audioProcessor,
    required CacheManager cacheManager,
  })  : _audioProcessor = audioProcessor,
        _cacheManager = cacheManager;

  @override
  Future<void> initialize() async {
    _player = AudioPlayer();

    // Load saved volume
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble('volume') ?? 1.0;
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('Failed to load volume preference: $e');
    }

    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      _updatePlaybackState(playerState);
    });

    // Listen to position updates
    _positionSubscription = _player.positionStream.listen((position) {
      final duration = _player.duration ?? Duration.zero;
      _positionController.add(PlaybackPosition(
        position: position,
        duration: duration,
        isPlaying: _player.playing,
      ));
    });

    // Listen to playback completion
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _completionController.add(null);
      }
    });
  }

  void _updatePlaybackState(PlayerState playerState) {
    PlaybackState newState;

    switch (playerState.processingState) {
      case ProcessingState.idle:
        newState = PlaybackState.stopped;
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        newState = PlaybackState.buffering;
        break;
      case ProcessingState.ready:
        newState = playerState.playing
            ? PlaybackState.playing
            : PlaybackState.paused;
        break;
      case ProcessingState.completed:
        newState = PlaybackState.stopped;
        break;
    }

    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  @override
  Future<void> play(AudioFile file) async {
    try {
      _currentFile = file;

      // Check cache first
      final fileHash = CacheManagerImpl.generateFileHash(file.path);
      String? instrumentalPath = await _cacheManager.getCachedInstrumental(fileHash);

      if (instrumentalPath == null) {
        // Not cached - need to process
        _state = PlaybackState.processing;
        _stateController.add(_state);

        final result = await _audioProcessor.processAudio(file);

        // Store in cache
        await _cacheManager.storeInCache(
          fileHash: fileHash,
          instrumentalPath: result.instrumentalPath,
          originalPath: file.path,
        );

        instrumentalPath = result.instrumentalPath;
      }

      // Load and play
      if (kIsWeb) {
        // Web: Use blob URL
        await _player.setUrl(instrumentalPath);
      } else {
        // Mobile: Use file path
        await _player.setFilePath(instrumentalPath);
      }

      await _player.play();
    } catch (e, stackTrace) {
      _state = PlaybackState.stopped;
      _stateController.add(_state);
      throw VocalRemoverError.processingFailed(
        'Failed to play audio',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(
        'Failed to resume playback',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(
        'Failed to pause playback',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      _currentFile = null;
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(
        'Failed to stop playback',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(
        'Failed to seek',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      // Clamp volume between 0.0 and 1.0
      _volume = volume.clamp(0.0, 1.0);
      await _player.setVolume(_volume);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('volume', _volume);
    } catch (e) {
      debugPrint('Failed to set volume: $e');
    }
  }

  @override
  double get volume => _volume;

  @override
  PlaybackState get state => _state;

  @override
  AudioFile? get currentFile => _currentFile;

  @override
  PlaybackPosition get position {
    return PlaybackPosition(
      position: _player.position,
      duration: _player.duration ?? Duration.zero,
      isPlaying: _player.playing,
    );
  }

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<PlaybackPosition> get positionStream => _positionController.stream;

  @override
  Stream<void> get completionStream => _completionController.stream;

  @override
  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _player.dispose();
    await _stateController.close();
    await _positionController.close();
    await _completionController.close();
  }
}
