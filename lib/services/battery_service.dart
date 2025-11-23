import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing battery-aware features
class BatteryService {
  final Battery _battery = Battery();
  bool _batterySaverEnabled = false;
  int _batteryLevel = 100;

  final StreamController<bool> _batterySaverController =
      StreamController<bool>.broadcast();
  final StreamController<int> _batteryLevelController =
      StreamController<int>.broadcast();

  StreamSubscription? _batterySubscription;

  static const int _lowBatteryThreshold = 20;
  static const String _batterySaverKey = 'battery_saver_enabled';

  /// Initialize battery monitoring
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web doesn't have battery API in Flutter yet
      return;
    }

    try {
      // Load saved preference
      final prefs = await SharedPreferences.getInstance();
      _batterySaverEnabled = prefs.getBool(_batterySaverKey) ?? false;

      // Get initial battery level
      _batteryLevel = await _battery.batteryLevel;
      _batteryLevelController.add(_batteryLevel);

      // Listen to battery state changes
      _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
        _batteryLevel = await _battery.batteryLevel;
        _batteryLevelController.add(_batteryLevel);

        // Auto-enable battery saver if battery is low and user hasn't disabled it
        if (_batteryLevel < _lowBatteryThreshold && !_batterySaverEnabled) {
          await _updateBatterySaver(true, autoEnabled: true);
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize battery monitoring: $e');
    }
  }

  /// Enable or disable battery saver mode
  Future<void> setBatterySaverEnabled(bool enabled) async {
    await _updateBatterySaver(enabled, autoEnabled: false);
  }

  Future<void> _updateBatterySaver(bool enabled, {required bool autoEnabled}) async {
    _batterySaverEnabled = enabled;
    _batterySaverController.add(_batterySaverEnabled);

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_batterySaverKey, _batterySaverEnabled);
    } catch (e) {
      debugPrint('Failed to save battery saver preference: $e');
    }

    if (autoEnabled) {
      debugPrint('Battery saver auto-enabled due to low battery');
    }
  }

  /// Get current battery saver state
  bool get isBatterySaverEnabled => _batterySaverEnabled;

  /// Get current battery level
  int get batteryLevel => _batteryLevel;

  /// Check if battery is low
  bool get isLowBattery => _batteryLevel < _lowBatteryThreshold;

  /// Stream of battery saver state changes
  Stream<bool> get batterySaverStream => _batterySaverController.stream;

  /// Stream of battery level changes
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;

  /// Should look-ahead processing be disabled?
  bool get shouldDisableLookAhead {
    return _batterySaverEnabled && isLowBattery;
  }

  /// Get processing throttle delay (in milliseconds)
  /// Returns 1000ms when battery saver is active, 0 otherwise
  int get processingThrottleDelay {
    return _batterySaverEnabled ? 1000 : 0;
  }

  /// Dispose of resources
  void dispose() {
    _batterySubscription?.cancel();
    _batterySaverController.close();
    _batteryLevelController.close();
  }
}
