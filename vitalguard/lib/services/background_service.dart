import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

// Background task handler with ML-based fall detection
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(VitalGuardTaskHandler());
}

class VitalGuardTaskHandler extends TaskHandler {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  DateTime? _lastEmergencyAlert;

  // ML-based detection
  Interpreter? _interpreter;
  Timer? _samplingTimer;
  List<List<double>> _sensorDataBuffer = [];
  List<double>? _lastAccelData;
  List<double>? _lastGyroData;
  bool _isCollecting = false;

  // ML Model parameters
  static const int samplingRate = 20; // Hz
  static const int windowDuration = 20; // seconds
  static const int totalSamples = samplingRate * windowDuration; // 400
  static const int inputSize = totalSamples * 6; // 2400 (accel xyz + gyro xyz)
  static const double fallConfidenceThreshold = 0.70;

  // Activity labels (matching model output)
  static const Map<int, String> activityLabels = {
    0: 'fall',
    1: 'lfall', // Light fall
    2: 'light',
    3: 'rfall', // Real fall
    4: 'sit',
    5: 'step',
    6: 'walk',
  };

  static const int emergencyAlertCooldown = 30;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🔔 Background ML monitoring started');

    // Initialize ML model
    await _initializeModel();

    // Start sensor monitoring
    _startMonitoring();
  }

  Future<void> _initializeModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'models/fall_detection_model.tflite',
      );
      debugPrint('✅ Background: ML model loaded successfully');
    } catch (e) {
      debugPrint('❌ Background: Failed to load ML model: $e');
    }
  }

  void _startMonitoring() {
    // Subscribe to accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      _lastAccelData = [event.x, event.y, event.z];
    });

    // Subscribe to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen((
      GyroscopeEvent event,
    ) {
      _lastGyroData = [event.x, event.y, event.z];
    });

    // Start data collection window
    _startNewWindow();
  }

  void _startNewWindow() {
    if (_isCollecting) return;

    _isCollecting = true;
    _sensorDataBuffer.clear();

    debugPrint('📊 Background: Starting 20-second data collection');

    // Sample at 20 Hz (every 50ms)
    _samplingTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_lastAccelData != null && _lastGyroData != null) {
        final combinedSample = [..._lastAccelData!, ..._lastGyroData!];
        _sensorDataBuffer.add(combinedSample);

        if (_sensorDataBuffer.length >= totalSamples) {
          timer.cancel();
          _processWindow();
        }
      }
    });

    // Safety timeout
    Timer(Duration(seconds: 25), () {
      if (_sensorDataBuffer.length < totalSamples && _isCollecting) {
        debugPrint('⚠️ Background: Window timeout');
        _isCollecting = false;
        _startNewWindow();
      }
    });
  }

  Future<void> _processWindow() async {
    if (_interpreter == null) {
      debugPrint('⚠️ Background: Model not loaded, skipping inference');
      _isCollecting = false;
      _startNewWindow();
      return;
    }

    try {
      // Check if there's actual movement (filter stationary phone)
      if (!_hasSignificantMovement()) {
        debugPrint('😴 Background: Phone stationary - skipping inference');
        _isCollecting = false;
        _startNewWindow();
        return;
      }

      // Flatten 2D array to 1D
      final flattenedData = <double>[];
      for (final sample in _sensorDataBuffer) {
        flattenedData.addAll(sample);
      }

      // Prepare input/output tensors
      final input = [flattenedData];
      final output = List.filled(
        1,
        List.filled(7, 0.0),
      ).map((e) => List<double>.from(e)).toList();

      // Run inference
      _interpreter!.run(input, output);

      // Get prediction
      final probabilities = output[0];
      int predictedClassIndex = 0;
      double maxProbability = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          predictedClassIndex = i;
        }
      }

      final predictedActivity =
          activityLabels[predictedClassIndex] ?? 'unknown';

      debugPrint(
        '🎯 Background: Prediction: $predictedActivity (${(maxProbability * 100).toStringAsFixed(1)}%)',
      );

      // Check if fall detected
      if ((predictedActivity == 'fall' ||
              predictedActivity == 'lfall' ||
              predictedActivity == 'rfall') &&
          maxProbability >= 0.85) {
        // Increased to 85% threshold
        _triggerBackgroundEmergency(predictedActivity, maxProbability);
      }
    } catch (e) {
      debugPrint('❌ Background: Inference error: $e');
    }

    // Start next window
    _isCollecting = false;
    _startNewWindow();
  }

  void _triggerBackgroundEmergency(String fallType, double confidence) {
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
      'fallType': fallType,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint(
      '🚨 BACKGROUND ML: $fallType detected (${(confidence * 100).toStringAsFixed(1)}%) - notifying app',
    );
  }

  /// Check if there's significant movement in the collected data
  bool _hasSignificantMovement() {
    if (_sensorDataBuffer.isEmpty) return false;

    double sumAccelX = 0, sumAccelY = 0, sumAccelZ = 0;

    for (var sample in _sensorDataBuffer) {
      sumAccelX += sample[0];
      sumAccelY += sample[1];
      sumAccelZ += sample[2];
    }

    double avgAccelX = sumAccelX / _sensorDataBuffer.length;
    double avgAccelY = sumAccelY / _sensorDataBuffer.length;
    double avgAccelZ = sumAccelZ / _sensorDataBuffer.length;

    double varianceX = 0, varianceY = 0, varianceZ = 0;

    for (var sample in _sensorDataBuffer) {
      varianceX += (sample[0] - avgAccelX) * (sample[0] - avgAccelX);
      varianceY += (sample[1] - avgAccelY) * (sample[1] - avgAccelY);
      varianceZ += (sample[2] - avgAccelZ) * (sample[2] - avgAccelZ);
    }

    varianceX /= _sensorDataBuffer.length;
    varianceY /= _sensorDataBuffer.length;
    varianceZ /= _sensorDataBuffer.length;

    double totalVariance = varianceX + varianceY + varianceZ;
    const double minVarianceThreshold = 0.5;

    return totalVariance >= minVarianceThreshold;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Update notification to show active monitoring
    final samplesCollected = _sensorDataBuffer.length;
    FlutterForegroundTask.updateService(
      notificationTitle: 'VitalGuard ML Active',
      notificationText:
          'AI Fall Detection: ${samplesCollected}/$totalSamples samples',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('Background ML monitoring stopped');
    _samplingTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _interpreter?.close();
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
