import 'audio_file.dart';

/// Status of a processing task
enum TaskStatus {
  queued,
  processing,
  completed,
  cancelled,
  failed,
}

/// Represents a vocal removal processing task
class ProcessingTask {
  final String id;
  final AudioFile audioFile;
  final TaskStatus status;
  final double progress; // 0.0 to 1.0
  final DateTime startTime;
  final DateTime? completionTime;
  final String? errorMessage;

  const ProcessingTask({
    required this.id,
    required this.audioFile,
    required this.status,
    required this.progress,
    required this.startTime,
    this.completionTime,
    this.errorMessage,
  });

  /// Create ProcessingTask from JSON
  factory ProcessingTask.fromJson(Map<String, dynamic> json) {
    return ProcessingTask(
      id: json['id'] as String,
      audioFile: AudioFile.fromJson(json['audioFile'] as Map<String, dynamic>),
      status: TaskStatus.values[json['status'] as int],
      progress: (json['progress'] as num).toDouble(),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      completionTime: json['completionTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completionTime'] as int)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert ProcessingTask to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioFile': audioFile.toJson(),
      'status': status.index,
      'progress': progress,
      'startTime': startTime.millisecondsSinceEpoch,
      'completionTime': completionTime?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
    };
  }

  /// Create a copy with optional field updates
  ProcessingTask copyWith({
    String? id,
    AudioFile? audioFile,
    TaskStatus? status,
    double? progress,
    DateTime? startTime,
    DateTime? completionTime,
    String? errorMessage,
  }) {
    return ProcessingTask(
      id: id ?? this.id,
      audioFile: audioFile ?? this.audioFile,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if task is in a terminal state
  bool get isComplete =>
      status == TaskStatus.completed ||
      status == TaskStatus.cancelled ||
      status == TaskStatus.failed;

  /// Check if task is currently running
  bool get isRunning => status == TaskStatus.processing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProcessingTask(id: $id, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}
