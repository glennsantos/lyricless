import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_processor.dart';
import '../models/audio_file.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of AudioProcessor using Python CLI with Spleeter
class PythonAudioProcessor implements AudioProcessor {
  bool _isProcessing = false;
  bool _isInitialized = false;
  Process? _currentProcess;

  // Paths to Python environment and script
  static const String _pythonPath = '/Users/aryeh/dev/lyricless/python/venv/bin/python';
  static const String _scriptPath = '/Users/aryeh/dev/lyricless/python/vocal_remover_cli.py';

  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Check if Python executable exists
      final pythonFile = File(_pythonPath);
      if (!await pythonFile.exists()) {
        throw VocalRemoverError.modelLoadFailed(
          'Python interpreter not found at: $_pythonPath'
        );
      }

      // Check if Python script exists
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        throw VocalRemoverError.modelLoadFailed(
          'Python script not found at: $_scriptPath'
        );
      }

      // Verify Python environment by running a quick test
      try {
        final result = await Process.run(
          _pythonPath,
          ['-c', 'import spleeter; print("OK")'],
        );
        
        if (result.exitCode != 0) {
          throw VocalRemoverError.modelLoadFailed(
            'Spleeter not installed in Python environment: ${result.stderr}'
          );
        }
      } catch (e) {
        throw VocalRemoverError.modelLoadFailed(
          'Failed to verify Python environment: $e'
        );
      }

      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      _isInitialized = false;
      if (e is VocalRemoverError) {
        rethrow;
      }
      throw VocalRemoverError.modelLoadFailed(e, stackTrace);
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
    final startTime = DateTime.now();

    try {
      onProgress?.call(0.0);

      // Validate input file exists
      final inputFile = File(audioFile.path);
      if (!await inputFile.exists()) {
        throw VocalRemoverError.fileNotFound(audioFile.path);
      }

      // Determine output path
      final outputPath = await _generateOutputPath(audioFile);

      // Start Python process with JSON progress mode
      debugPrint('Starting vocal removal process...');
      debugPrint('Input: ${audioFile.path}');
      debugPrint('Output: $outputPath');

      _currentProcess = await Process.start(
        _pythonPath,
        [
          _scriptPath,
          audioFile.path,
          outputPath,
          '--json-progress',
        ],
        mode: ProcessStartMode.normal,
      );

      // Monitor progress from stdout (JSON format)
      final progressCompleter = Completer<void>();
      final errorBuffer = StringBuffer();

      _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              try {
                final data = jsonDecode(line);
                
                if (data.containsKey('progress')) {
                  final progress = (data['progress'] as num).toDouble();
                  final status = data['status'] as String?;
                  debugPrint('Progress: ${(progress * 100).toStringAsFixed(1)}% - $status');
                  onProgress?.call(progress);
                }
                
                if (data.containsKey('success') && data['success'] == true) {
                  debugPrint('Processing complete!');
                  progressCompleter.complete();
                }
              } catch (e) {
                debugPrint('Failed to parse progress JSON: $line');
              }
            },
            onError: (error) {
              debugPrint('Error reading stdout: $error');
            },
            onDone: () {
              if (!progressCompleter.isCompleted) {
                progressCompleter.complete();
              }
            },
          );

      // Collect stderr for error reporting
      _currentProcess!.stderr
          .transform(utf8.decoder)
          .listen((data) {
            errorBuffer.write(data);
            // Also log to debug console
            debugPrint('[Python stderr] $data');
          });

      // Wait for process completion
      await progressCompleter.future;
      final exitCode = await _currentProcess!.exitCode;

      if (exitCode != 0) {
        final errorMessage = errorBuffer.toString().trim();
        throw VocalRemoverError.processingFailed(
          'Python process failed with exit code $exitCode: $errorMessage'
        );
      }

      // Verify output file was created
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw VocalRemoverError.processingFailed(
          'Output file was not created: $outputPath'
        );
      }

      onProgress?.call(1.0);
      final processingTime = DateTime.now().difference(startTime);

      debugPrint('Vocal removal completed in ${processingTime.inSeconds}s');

      return ProcessingResult(
        instrumentalPath: outputPath,
        processingTime: processingTime,
      );
    } catch (e, stackTrace) {
      if (e is VocalRemoverError) {
        rethrow;
      }
      throw VocalRemoverError.processingFailed(e.toString(), e, stackTrace);
    } finally {
      _currentProcess = null;
      _isProcessing = false;
    }
  }

  Future<String> _generateOutputPath(AudioFile audioFile) async {
    try {
      // Get temporary directory for output
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Extract original filename without extension
      final originalFile = File(audioFile.path);
      final baseName = originalFile.uri.pathSegments.last.split('.').first;
      
      // Create output filename
      final outputFileName = '${baseName}_instrumental_$timestamp.mp3';
      final outputPath = '${tempDir.path}/$outputFileName';
      
      return outputPath;
    } catch (e) {
      throw VocalRemoverError.processingFailed('Failed to generate output path: $e');
    }
  }

  @override
  Future<void> cancelProcessing() async {
    if (_currentProcess != null) {
      debugPrint('Cancelling vocal removal process...');
      _currentProcess!.kill(ProcessSignal.sigterm);
      _currentProcess = null;
      _isProcessing = false;
    }
  }

  @override
  bool get isProcessing => _isProcessing;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> dispose() async {
    await cancelProcessing();
    _isInitialized = false;
  }
}
