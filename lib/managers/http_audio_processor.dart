import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'audio_processor.dart';
import '../models/audio_file.dart';
import '../models/vocal_remover_error.dart';

/// Implementation of AudioProcessor that communicates with a remote Python API
class HttpAudioProcessor implements AudioProcessor {
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _baseUrl = 'http://127.0.0.1:8000';
  
  static const String _prefKeyUrl = 'vocal_remover_api_url';
  
  @override
  Future<bool> initialize() async {
    // Always reload URL on initialization
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKeyUrl) ?? 'http://127.0.0.1:8000';
    
    // If running on Android emulator, 127.0.0.1 won't work, default to 10.0.2.2 if not set
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && _baseUrl == 'http://127.0.0.1:8000') {
       _baseUrl = 'http://10.0.2.2:8000';
    }
    
    debugPrint('Initializing HttpAudioProcessor with URL: $_baseUrl');
    
    try {
      // Check if server is reachable
      final response = await http.get(Uri.parse('$_baseUrl/')).timeout(
        const Duration(seconds: 2),
      );
      
      if (response.statusCode == 200) {
        _isInitialized = true;
        debugPrint('HttpAudioProcessor initialized: Server is reachable');
        return true;
      } else {
        throw VocalRemoverError.modelLoadFailed(
          'Server returned status ${response.statusCode}'
        );
      }
    } catch (e) {
      debugPrint('HttpAudioProcessor initialization failed: $e');
      // We don't throw here to allow app to start, but processing will fail later
      // or we could try to start the server if local?
      // For now, just mark as not initialized.
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<ProcessingResult> processAudio(
    AudioFile audioFile, {
    ProgressCallback? onProgress,
  }) async {
    if (!_isInitialized) {
      // Try to re-initialize
      final success = await initialize();
      if (!success) {
        throw VocalRemoverError.processingFailed(
          'Server not reachable. Please ensure the Python server is running.'
        );
      }
    }

    if (_isProcessing) {
      throw VocalRemoverError.processingFailed('Already processing another file');
    }

    _isProcessing = true;
    final startTime = DateTime.now();

    try {
      onProgress?.call(0.1); // Uploading
      
      final uri = Uri.parse('$_baseUrl/process');
      final request = http.MultipartRequest('POST', uri);
      
      final file = File(audioFile.path);
      if (!await file.exists()) {
        throw VocalRemoverError.fileNotFound(audioFile.path);
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      ));
      
      debugPrint('Uploading file to $uri...');
      final streamResponse = await request.send();
      
      onProgress?.call(0.5); // Processing on server
      
      if (streamResponse.statusCode != 200) {
        final body = await streamResponse.stream.bytesToString();
        throw VocalRemoverError.processingFailed(
          'Server error (${streamResponse.statusCode}): $body'
        );
      }
      
      // Download result
      debugPrint('Downloading result...');
      final response = await http.Response.fromStream(streamResponse);
      
      onProgress?.call(0.9); // Saving
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName = '${file.uri.pathSegments.last}_instrumental_$timestamp.mp3';
      final outputPath = '${tempDir.path}/$outputFileName';
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(response.bodyBytes);
      
      onProgress?.call(1.0);
      
      final processingTime = DateTime.now().difference(startTime);
      debugPrint('Processing complete in ${processingTime.inSeconds}s');
      
      return ProcessingResult(
        instrumentalPath: outputPath,
        processingTime: processingTime,
      );
      
    } catch (e, stackTrace) {
      throw VocalRemoverError.processingFailed(e.toString(), e, stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> cancelProcessing() async {
    // HTTP cancellation not fully implemented in this simple version
    _isProcessing = false;
  }

  @override
  bool get isProcessing => _isProcessing;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
