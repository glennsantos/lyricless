import 'package:flutter/foundation.dart';

/// Represents the initialization state of a service or component
enum InitializationStatus {
  notStarted,
  inProgress,
  success,
  failed,
}

/// Model for tracking initialization state
class InitializationState {
  final String serviceName;
  final InitializationStatus status;
  final String? message;
  final Object? error;

  const InitializationState({
    required this.serviceName,
    required this.status,
    this.message,
    this.error,
  });

  InitializationState copyWith({
    String? serviceName,
    InitializationStatus? status,
    String? message,
    Object? error,
  }) {
    return InitializationState(
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  bool get isSuccess => status == InitializationStatus.success;
  bool get isFailed => status == InitializationStatus.failed;
  bool get isInProgress => status == InitializationStatus.inProgress;
}

/// Notifier for app initialization state
class AppInitializationNotifier extends ChangeNotifier {
  final Map<String, InitializationState> _services = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Map<String, InitializationState> get services => Map.unmodifiable(_services);

  bool get hasErrors => _services.values.any((state) => state.isFailed);
  bool get isComplete => _services.values.every((state) => state.isSuccess);

  List<InitializationState> get failedServices =>
      _services.values.where((state) => state.isFailed).toList();

  void updateService(InitializationState state) {
    _services[state.serviceName] = state;
    notifyListeners();
  }

  void setInitialized() {
    _isInitialized = true;
    notifyListeners();
  }

  void reset() {
    _services.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
