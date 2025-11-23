import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'audio_processor.dart';
import '../models/audio_file.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of AudioProcessor with TensorFlow Lite
class AudioProcessorImpl implements AudioProcessor {
  Interpreter? _interpreter;
  bool _isProcessing = false;
  bool _isCancelled = false;
  bool _isInitialized = false;

  static const String _modelAssetPath = 'assets/models/vocal_remover.tflite';
  static const int _sampleRate = 44100;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Load model from assets
      _interpreter = await _loadModel();

      if (_interpreter == null) {
        throw VocalRemoverError.modelLoadFailed('Failed to create interpreter');
      }

      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      _isInitialized = false;
      throw VocalRemoverError.modelLoadFailed(e, stackTrace);
    }
  }

  Future<Interpreter?> _loadModel() async {
    try {
      if (kIsWeb) {
        // Web: TensorFlow.js would be used instead
        // For now, we'll prepare for it
        debugPrint('Web platform: TensorFlow.js should be used');
        return null; // Web implementation pending
      }

      // Mobile: Load TFLite model
      final options = InterpreterOptions();

      // Enable GPU acceleration
      if (Platform.isAndroid) {
        // Android: Use NNAPI delegate
        options.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        // iOS: Use Metal delegate
        options.addDelegate(GpuDelegateV2());
      }

      // Set number of threads
      options.threads = 4;

      return await Interpreter.fromAsset(
        _modelAssetPath,
        options: options,
      );
    } catch (e) {
      debugPrint('Failed to load model with GPU, trying CPU: $e');
      // Fallback to CPU
      try {
        return await Interpreter.fromAsset(_modelAssetPath);
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  Future<ProcessingResult> processAudio(
    AudioFile audioFile, {
    ProgressCallback? onProgress,
  }) async {
    if (!_isInitialized) {
      throw VocalRemoverError.processingFailed('Processor not initialized');
    }

    if (_isProcessing) {
      throw VocalRemoverError.processingFailed('Already processing another file');
    }

    _isProcessing = true;
    _isCancelled = false;
    final startTime = DateTime.now();

    try {
      onProgress?.call(0.0);

      // Step 1: Load and preprocess audio (0-30%)
      final audioData = await _loadAudioFile(audioFile);
      if (_isCancelled) throw _CancelledException();
      onProgress?.call(0.1);

      final pcmData = await _convertToPCM(audioData);
      if (_isCancelled) throw _CancelledException();
      onProgress?.call(0.2);

      final spectrogram = await _generateSpectrogram(pcmData);
      if (_isCancelled) throw _CancelledException();
      onProgress?.call(0.3);

      // Step 2: Run inference (30-70%)
      final processedSpectrogram = await _runInference(
        spectrogram,
        onProgress: (p) => onProgress?.call(0.3 + (p * 0.4)),
      );
      if (_isCancelled) throw _CancelledException();

      // Step 3: Post-process and save (70-100%)
      onProgress?.call(0.7);
      final instrumentalData = await _invertSpectrogram(processedSpectrogram);
      if (_isCancelled) throw _CancelledException();
      onProgress?.call(0.8);

      final outputPath = await _saveInstrumental(instrumentalData, audioFile);
      if (_isCancelled) throw _CancelledException();
      onProgress?.call(1.0);

      final processingTime = DateTime.now().difference(startTime);

      return ProcessingResult(
        instrumentalPath: outputPath,
        processingTime: processingTime,
      );
    } on _CancelledException {
      throw VocalRemoverError.processingFailed('Processing was cancelled');
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(e.toString(), e, stackTrace);
    } finally {
      _isProcessing = false;
      _isCancelled = false;
    }
  }

  Future<Uint8List> _loadAudioFile(AudioFile file) async {
    try {
      if (kIsWeb) {
        // Web: Load from blob or file input
        throw UnimplementedError('Web audio loading not yet implemented');
      } else {
        // Mobile: Load from file system
        final audioFile = File(file.path);
        if (!await audioFile.exists()) {
          throw VocalRemoverError.fileNotFound(file.path);
        }
        return await audioFile.readAsBytes();
      }
    } catch (e) {
      throw VocalRemoverError.processingFailed('Failed to load audio file', e);
    }
  }

  Future<Float32List> _convertToPCM(Uint8List audioData) async {
    // Convert audio to PCM format at 44.1kHz
    // This would use platform-specific audio decoding
    // For now, this is a placeholder
    try {
      if (kIsWeb) {
        // Web: Use Web Audio API via platform channels
        throw UnimplementedError('Web PCM conversion not yet implemented');
      } else {
        // Mobile: Use platform channels for native decoding
        // Placeholder: return dummy data
        return Float32List(audioData.length);
      }
    } catch (e) {
      throw VocalRemoverError.processingFailed('PCM conversion failed', e);
    }
  }

  Future<List<Float32List>> _generateSpectrogram(Float32List pcmData) async {
    // Generate spectrogram using FFT
    // This would use platform-specific FFT implementations
    try {
      if (kIsWeb) {
        // Web: Use Web Audio API AnalyserNode
        throw UnimplementedError('Web FFT not yet implemented');
      } else {
        // Mobile: Use native FFT (vDSP on iOS, KissFFT on Android)
        // Placeholder: return dummy spectrogram
        return List.generate(10, (_) => Float32List(1024));
      }
    } catch (e) {
      throw VocalRemoverError.processingFailed('FFT generation failed', e);
    }
  }

  Future<List<Float32List>> _runInference(
    List<Float32List> spectrogram, {
    ProgressCallback? onProgress,
  }) async {
    if (_interpreter == null) {
      throw VocalRemoverError.processingFailed('Model not loaded');
    }

    try {
      // Prepare input tensor
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Run inference
      final output = List.generate(
        outputShape[0],
        (_) => Float32List(outputShape[1]),
      );

      // Process in chunks for progress updates
      onProgress?.call(0.5);

      _interpreter!.run(spectrogram, output);

      if (_isCancelled) throw _CancelledException();

      onProgress?.call(1.0);

      return output;
    } catch (e) {
      if (e is _CancelledException) rethrow;
      throw VocalRemoverError.processingFailed('Inference failed', e);
    }
  }

  Future<Float32List> _invertSpectrogram(List<Float32List> spectrogram) async {
    // Convert spectrogram back to PCM using inverse FFT
    try {
      if (kIsWeb) {
        // Web: Use Web Audio API
        throw UnimplementedError('Web iFFT not yet implemented');
      } else {
        // Mobile: Use native iFFT
        // Placeholder: return dummy audio
        return Float32List(44100 * 60); // 1 minute placeholder
      }
    } catch (e) {
      throw VocalRemoverError.processingFailed('Inverse FFT failed', e);
    }
  }

  Future<String> _saveInstrumental(
    Float32List audioData,
    AudioFile originalFile,
  ) async {
    try {
      if (kIsWeb) {
        // Web: Create Blob and return object URL
        throw UnimplementedError('Web audio save not yet implemented');
      } else {
        // Mobile: Save to cache directory as WAV
        final cacheDir = await getTemporaryDirectory();
        final outputPath = '${cacheDir.path}/instrumental_${DateTime.now().millisecondsSinceEpoch}.wav';

        // Write WAV file
        // This is a placeholder - actual WAV encoding needed
        final file = File(outputPath);
        await file.writeAsBytes(audioData.buffer.asUint8List());

        return outputPath;
      }
    } catch (e) {
      throw VocalRemoverError.processingFailed('Failed to save output', e);
    }
  }

  @override
  Future<void> cancelProcessing() async {
    _isCancelled = true;
  }

  @override
  bool get isProcessing => _isProcessing;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _isProcessing = false;
  }
}

/// Internal exception for cancelled operations
class _CancelledException implements Exception {}
