import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Background task handler
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(VitalGuardTaskHandler());
}

class VitalGuardTaskHandler extends TaskHandler {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _freefallStartTime;
  bool _inFreefall = false;
  DateTime? _lastEmergencyAlert;

  // Thresholds (same as SensorService)
  static const double fallThreshold = 140.0;
  static const double freeThreshold = 50.0;
  static const double minimumFreefallDuration = 0.3;
  static const int emergencyAlertCooldown = 30;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🔔 Background monitoring started');
    _startMonitoring();
  }

  void _startMonitoring() {
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      _detectFall(magnitude);
    });
  }

  void _detectFall(double magnitude) {
    if (_inFreefall) {
      if (magnitude > fallThreshold) {
        if (_freefallStartTime != null) {
          final freefallDuration =
              DateTime.now().difference(_freefallStartTime!).inMilliseconds /
              1000.0;

          if (freefallDuration >= minimumFreefallDuration) {
            _triggerBackgroundEmergency();
            _inFreefall = false;
            _freefallStartTime = null;
          } else {
            _inFreefall = false;
            _freefallStartTime = null;
          }
        }
      }
    } else {
      if (magnitude < freeThreshold) {
        _inFreefall = true;
        _freefallStartTime = DateTime.now();
      }
    }
  }

  void _triggerBackgroundEmergency() {
    // Check cooldown
    if (_lastEmergencyAlert != null) {
      final timeSinceLastAlert = DateTime.now()
          .difference(_lastEmergencyAlert!)
          .inSeconds;
      if (timeSinceLastAlert < emergencyAlertCooldown) {
        return;
      }
    }

    _lastEmergencyAlert = DateTime.now();

    // Send data to foreground to trigger emergency
    FlutterForegroundTask.sendDataToMain({
      'action': 'emergency_detected',
      'type': 'fall',
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('🚨 BACKGROUND: Fall detected - notifying app');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Update notification every minute to show monitoring is active
    FlutterForegroundTask.updateService(
      notificationTitle: 'VitalGuard Active',
      notificationText: 'Monitoring your safety 24/7',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('Background monitoring stopped');
    _accelerometerSubscription?.cancel();
  }
}

class BackgroundMonitoringService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vitalguard_monitoring',
        channelName: 'VitalGuard Health Monitoring',
        channelDescription: 'Continuous fall detection and health monitoring',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000,
        ), // Check every 5 seconds
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
    debugPrint('✅ Background service initialized');
  }

  static Future<bool> startService() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request notification permission for Android 13+
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'VitalGuard Active',
        notificationText: 'Monitoring your safety 24/7',
        callback: startCallback,
      );

      debugPrint('✅ Background monitoring started');
      return true;
    }

    return false;
  }

  static Future<bool> stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('⏹️ Background monitoring stopped');
      return true;
    }
    return false;
  }

  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}
