import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyricless/models/audio_file.dart';
import 'package:lyricless/models/processing_task.dart';
import 'package:lyricless/models/vocal_remover_error.dart';

void main() {
  group('AudioFile Tests', () {
    test('AudioFile serialization and deserialization', () {
      final audioFile = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        format: 'mp3',
        isDRMProtected: false,
        albumArtwork: Uint8List.fromList([1, 2, 3, 4]),
      );

      final json = audioFile.toJson();
      final restored = AudioFile.fromJson(json);

      expect(restored.id, equals(audioFile.id));
      expect(restored.path, equals(audioFile.path));
      expect(restored.title, equals(audioFile.title));
      expect(restored.artist, equals(audioFile.artist));
      expect(restored.album, equals(audioFile.album));
      expect(restored.duration, equals(audioFile.duration));
      expect(restored.format, equals(audioFile.format));
      expect(restored.isDRMProtected, equals(audioFile.isDRMProtected));
      expect(restored.albumArtwork, equals(audioFile.albumArtwork));
    });

    test('AudioFile copyWith creates correct copy', () {
      final audioFile = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      final updated = audioFile.copyWith(title: 'New Title');

      expect(updated.title, equals('New Title'));
      expect(updated.id, equals(audioFile.id));
      expect(updated.artist, equals(audioFile.artist));
    });

    test('AudioFile equality based on id and path', () {
      final file1 = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      final file2 = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Different Title',
        artist: 'Different Artist',
        album: 'Different Album',
        duration: const Duration(minutes: 4),
        format: 'wav',
        isDRMProtected: true,
      );

      final file3 = AudioFile(
        id: 'different_id',
        path: '/path/to/different.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      expect(file1, equals(file2));
      expect(file1, isNot(equals(file3)));
    });
  });

  group('ProcessingTask Tests', () {
    test('ProcessingTask serialization and deserialization', () {
      final audioFile = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      final task = ProcessingTask(
        id: 'task_id',
        audioFile: audioFile,
        status: TaskStatus.processing,
        progress: 0.5,
        startTime: DateTime(2024, 1, 1),
        completionTime: DateTime(2024, 1, 1, 0, 5),
        errorMessage: 'Test error',
      );

      final json = task.toJson();
      final restored = ProcessingTask.fromJson(json);

      expect(restored.id, equals(task.id));
      expect(restored.audioFile.id, equals(task.audioFile.id));
      expect(restored.status, equals(task.status));
      expect(restored.progress, equals(task.progress));
      expect(
        restored.startTime.millisecondsSinceEpoch,
        equals(task.startTime.millisecondsSinceEpoch),
      );
      expect(
        restored.completionTime?.millisecondsSinceEpoch,
        equals(task.completionTime?.millisecondsSinceEpoch),
      );
      expect(restored.errorMessage, equals(task.errorMessage));
    });

    test('ProcessingTask isComplete returns correct value', () {
      final audioFile = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      final queuedTask = ProcessingTask(
        id: 'task1',
        audioFile: audioFile,
        status: TaskStatus.queued,
        progress: 0.0,
        startTime: DateTime.now(),
      );

      final processingTask = ProcessingTask(
        id: 'task2',
        audioFile: audioFile,
        status: TaskStatus.processing,
        progress: 0.5,
        startTime: DateTime.now(),
      );

      final completedTask = ProcessingTask(
        id: 'task3',
        audioFile: audioFile,
        status: TaskStatus.completed,
        progress: 1.0,
        startTime: DateTime.now(),
      );

      final cancelledTask = ProcessingTask(
        id: 'task4',
        audioFile: audioFile,
        status: TaskStatus.cancelled,
        progress: 0.3,
        startTime: DateTime.now(),
      );

      final failedTask = ProcessingTask(
        id: 'task5',
        audioFile: audioFile,
        status: TaskStatus.failed,
        progress: 0.7,
        startTime: DateTime.now(),
      );

      expect(queuedTask.isComplete, isFalse);
      expect(processingTask.isComplete, isFalse);
      expect(completedTask.isComplete, isTrue);
      expect(cancelledTask.isComplete, isTrue);
      expect(failedTask.isComplete, isTrue);
    });

    test('ProcessingTask isRunning returns correct value', () {
      final audioFile = AudioFile(
        id: 'test_id',
        path: '/path/to/file.mp3',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3),
        format: 'mp3',
        isDRMProtected: false,
      );

      final processingTask = ProcessingTask(
        id: 'task1',
        audioFile: audioFile,
        status: TaskStatus.processing,
        progress: 0.5,
        startTime: DateTime.now(),
      );

      final completedTask = ProcessingTask(
        id: 'task2',
        audioFile: audioFile,
        status: TaskStatus.completed,
        progress: 1.0,
        startTime: DateTime.now(),
      );

      expect(processingTask.isRunning, isTrue);
      expect(completedTask.isRunning, isFalse);
    });
  });

  group('VocalRemoverError Tests', () {
    test('VocalRemoverError factory methods create correct types', () {
      final unsupportedFormat = VocalRemoverError.unsupportedFormat('xyz');
      expect(unsupportedFormat.type, equals(ErrorType.unsupportedFormat));

      final drmProtected = VocalRemoverError.drmProtected();
      expect(drmProtected.type, equals(ErrorType.drmProtected));

      final processingFailed = VocalRemoverError.processingFailed('test reason');
      expect(processingFailed.type, equals(ErrorType.processingFailed));

      final modelLoadFailed = VocalRemoverError.modelLoadFailed('test error');
      expect(modelLoadFailed.type, equals(ErrorType.modelLoadFailed));

      final cacheError = VocalRemoverError.cacheError('test reason');
      expect(cacheError.type, equals(ErrorType.cacheError));

      final fileNotFound = VocalRemoverError.fileNotFound('/path/to/file');
      expect(fileNotFound.type, equals(ErrorType.fileNotFound));

      final insufficientStorage = VocalRemoverError.insufficientStorage();
      expect(insufficientStorage.type, equals(ErrorType.insufficientStorage));

      final networkError = VocalRemoverError.networkError('test reason');
      expect(networkError.type, equals(ErrorType.networkError));

      final unknown = VocalRemoverError.unknown('test message');
      expect(unknown.type, equals(ErrorType.unknown));
    });

    test('VocalRemoverError isRecoverable returns correct value', () {
      final modelLoadFailed = VocalRemoverError.modelLoadFailed('test');
      expect(modelLoadFailed.isRecoverable, isFalse);

      final drmProtected = VocalRemoverError.drmProtected();
      expect(drmProtected.isRecoverable, isFalse);

      final unsupportedFormat = VocalRemoverError.unsupportedFormat('xyz');
      expect(unsupportedFormat.isRecoverable, isFalse);

      final processingFailed = VocalRemoverError.processingFailed('test');
      expect(processingFailed.isRecoverable, isTrue);

      final cacheError = VocalRemoverError.cacheError('test');
      expect(cacheError.isRecoverable, isTrue);
    });

    test('VocalRemoverError userMessage returns user-friendly message', () {
      final unsupportedFormat = VocalRemoverError.unsupportedFormat('xyz');
      expect(unsupportedFormat.userMessage, contains('not supported'));

      final processingFailed = VocalRemoverError.processingFailed('test');
      expect(processingFailed.userMessage, contains('remove vocals'));

      final modelLoadFailed = VocalRemoverError.modelLoadFailed('test');
      expect(modelLoadFailed.userMessage, contains('initialization'));
    });
  });
}
