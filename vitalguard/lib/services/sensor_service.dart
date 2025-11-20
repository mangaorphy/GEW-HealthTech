import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';
import '../models/event_log.dart';

class SensorService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  SensorData? _currentAccelData;
  SensorData? _currentGyroData;

  bool _isMonitoring = false;
  double _heartRate = 72.0;
  bool _movementDetected = false;
  bool _fallDetected = false;
  bool _inFreefall = false;

  // Sensor raw values
  double _accelerometerX = 0.0;
  double _accelerometerY = 0.0;
  double _accelerometerZ = 0.0;
  double _gyroscopeX = 0.0;
  double _gyroscopeY = 0.0;
  double _gyroscopeZ = 0.0;

  // Emergency callback
  Function(EventType)? onEmergencyDetected;
  DateTime? _lastEmergencyAlert;
  DateTime? _freefallStartTime;
  static const int emergencyAlertCooldown =
      30; // 30 seconds between alerts (prevents spam but allows real emergencies)

  // Movement pattern detection
  String _movementPattern = 'Normal';
  DateTime _lastMovementTime = DateTime.now();
  List<double> _accelerationHistory = [];
  List<double> _gyroHistory = [];
  double _currentMagnitude = 0.0;
  int _erraticShakeCount = 0;
  bool _lackOfMovement = false;
  bool _erraticShaking = false;
  bool _rapidImpact = false;
  bool _collapsePattern = false;

  // Thresholds for movement detection
  // NOTE: Phone at rest reads ~96-97 m/s² due to gravity (9.8 m/s² * sqrt(x²+y²+z²))
  static const double gravityBaseline = 97.0; // Typical stationary reading
  static const double noMovementThreshold = 2.0; // m/s² variation from baseline
  static const double noMovementDuration = 30.0; // seconds
  static const double erraticShakeThreshold =
      120.0; // m/s² high frequency (well above baseline)
  static const int erraticShakeCount =
      5; // spikes in short time (increased to reduce false positives)
  static const double rapidImpactThreshold =
      150.0; // Significant deviation from baseline (~5-6g change)
  static const double collapseDeceleration =
      3.0; // gradual decrease (more sensitive)
  static const int historyBufferSize = 50; // ~1 second at 50Hz

  // Fall detection thresholds
  static const double fallThreshold =
      140.0; // Significant impact above baseline
  static const double freeThreshold =
      50.0; // Low reading during freefall (far below baseline)
  static const double minimumFreefallDuration =
      0.3; // seconds (300ms minimum freefall)

  final List<SensorData> _accelerometerBuffer = [];
  final int bufferSize = 50; // ~1 second at 50Hz

  // Fall detection callback
  Function(SensorData)? onFallDetected;

  // Getters
  bool get isMonitoring => _isMonitoring;
  double get heartRate => _heartRate;
  bool get movementDetected => _movementDetected;
  bool get fallDetected => _fallDetected;
  SensorData? get currentAccelData => _currentAccelData;
  SensorData? get currentGyroData => _currentGyroData;
  double get accelerometerX => _accelerometerX;
  double get accelerometerY => _accelerometerY;
  double get accelerometerZ => _accelerometerZ;
  double get gyroscopeX => _gyroscopeX;
  double get gyroscopeY => _gyroscopeY;
  double get gyroscopeZ => _gyroscopeZ;
  String get movementPattern => _movementPattern;
  bool get lackOfMovement => _lackOfMovement;
  bool get erraticShaking => _erraticShaking;
  bool get rapidImpact => _rapidImpact;
  bool get collapsePattern => _collapsePattern;
  double get currentMagnitude => _currentMagnitude;

  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Subscribe to accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        final data = SensorData(
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: DateTime.now(),
        );

        _currentAccelData = data;
        _processAccelerometerData(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );

    // Subscribe to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        final data = SensorData(
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: DateTime.now(),
        );

        _currentGyroData = data;

        // Update raw values
        _gyroscopeX = event.x;
        _gyroscopeY = event.y;
        _gyroscopeZ = event.z;

        // Calculate gyroscope magnitude for rotation detection
        final gyroMagnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Update gyro history
        _gyroHistory.add(gyroMagnitude);
        if (_gyroHistory.length > historyBufferSize) {
          _gyroHistory.removeAt(0);
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('Gyroscope error: $error');
      },
    );

    notifyListeners();
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _isMonitoring = false;
    _accelerometerBuffer.clear();
    notifyListeners();
  }

  void _processAccelerometerData(SensorData data) {
    // Add to buffer
    _accelerometerBuffer.add(data);
    if (_accelerometerBuffer.length > bufferSize) {
      _accelerometerBuffer.removeAt(0);
    }

    // Update raw values
    _accelerometerX = data.x;
    _accelerometerY = data.y;
    _accelerometerZ = data.z;

    final magnitude = data.magnitude;
    _currentMagnitude = magnitude;

    // Update acceleration history
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > historyBufferSize) {
      _accelerationHistory.removeAt(0);
    }

    // Check for movement
    _movementDetected = magnitude > 1.5;
    if (magnitude > 1.0) {
      _lastMovementTime = DateTime.now();
    }

    // Advanced movement pattern detection
    _detectMovementPatterns(magnitude);

    // Fall detection algorithm
    _detectFall(magnitude);
  }

  void _detectFall(double magnitude) {
    if (_inFreefall) {
      // Check if user has hit the ground (sudden stop after freefall)
      if (magnitude > fallThreshold) {
        // Verify minimum freefall duration to confirm it's a real fall
        if (_freefallStartTime != null) {
          final freefallDuration =
              DateTime.now().difference(_freefallStartTime!).inMilliseconds /
              1000.0;

          if (freefallDuration >= minimumFreefallDuration) {
            _fallDetected = true;
            _inFreefall = false;
            _freefallStartTime = null;
            debugPrint(
              '✅ CONFIRMED FALL! Freefall: ${freefallDuration.toStringAsFixed(2)}s, Impact: ${magnitude.toStringAsFixed(2)} m/s²',
            );
            // Trigger automatic emergency alert
            _triggerAutomaticEmergency(EventType.fall);
          } else {
            debugPrint(
              '⚠️ Impact detected but freefall too short (${freefallDuration.toStringAsFixed(2)}s) - likely phone drop',
            );
            _inFreefall = false;
            _freefallStartTime = null;
          }
        }
      }
    } else {
      // Check for freefall condition (start of potential fall)
      if (magnitude < freeThreshold) {
        _inFreefall = true;
        _freefallStartTime = DateTime.now();
        debugPrint('🔍 Freefall started: ${magnitude.toStringAsFixed(2)} m/s²');
      }
    }
  }

  void _detectMovementPatterns(double magnitude) {
    // Reset pattern flags
    _lackOfMovement = false;
    _erraticShaking = false;
    _rapidImpact = false;
    _collapsePattern = false;

    // 1. Lack of Movement Detection
    // Check if acceleration stays near gravity baseline (no significant change)
    final deviationFromBaseline = (magnitude - gravityBaseline).abs();
    if (deviationFromBaseline < noMovementThreshold) {
      final timeSinceMovement = DateTime.now()
          .difference(_lastMovementTime)
          .inSeconds;
      if (timeSinceMovement > noMovementDuration) {
        _lackOfMovement = true;
        _movementPattern = 'No Movement Detected';
        debugPrint(
          '⚠️ Lack of movement: ${timeSinceMovement}s (deviation: ${deviationFromBaseline.toStringAsFixed(2)} m/s²)',
        );
      }
    }

    // 2. Rapid Impact Detection (for monitoring only, NOT auto-trigger)
    // Detect sudden peak in acceleration for display purposes
    if (magnitude > rapidImpactThreshold) {
      _rapidImpact = true;
      _movementPattern = 'Rapid Impact Detected';
      debugPrint(
        '⚡ Rapid impact detected: ${magnitude.toStringAsFixed(2)} m/s² (monitoring only - waiting for freefall confirmation)',
      );
      // NOTE: Do NOT auto-trigger here - only fall detection (freefall + impact) triggers emergency
    }

    // 3. Erratic Shaking Detection
    // Count high-frequency spikes in recent history
    if (_accelerationHistory.length >= 10) {
      int highFrequencySpikes = 0;
      for (
        int i = _accelerationHistory.length - 10;
        i < _accelerationHistory.length;
        i++
      ) {
        if (_accelerationHistory[i] > erraticShakeThreshold) {
          highFrequencySpikes++;
        }
      }

      if (highFrequencySpikes >= erraticShakeCount) {
        _erraticShaking = true;
        _erraticShakeCount++;
        _movementPattern = 'Erratic Shaking Detected';
        debugPrint('⚡ Erratic shaking: $highFrequencySpikes spikes');
      } else {
        _erraticShakeCount = 0;
      }
    }

    // 4. Collapse Pattern Detection
    // Gradual movement decrease + sudden stillness
    if (_accelerationHistory.length >= 30) {
      final recent30 = _accelerationHistory.sublist(
        _accelerationHistory.length - 30,
      );
      final first10Avg = recent30.sublist(0, 10).reduce((a, b) => a + b) / 10;
      final middle10Avg = recent30.sublist(10, 20).reduce((a, b) => a + b) / 10;
      final last10Avg = recent30.sublist(20, 30).reduce((a, b) => a + b) / 10;

      // Check for gradual decrease pattern
      bool gradualDecrease =
          (first10Avg > middle10Avg) && (middle10Avg > last10Avg);
      bool suddenStillness = last10Avg < collapseDeceleration;

      if (gradualDecrease && suddenStillness) {
        _collapsePattern = true;
        _movementPattern = 'Collapse Pattern Detected';
        debugPrint(
          '💫 Collapse pattern: ${first10Avg.toStringAsFixed(2)} → ${middle10Avg.toStringAsFixed(2)} → ${last10Avg.toStringAsFixed(2)} m/s²',
        );
        // Trigger automatic emergency alert for collapse
        _triggerAutomaticEmergency(EventType.cardiacEvent);
      }
    }

    // Set normal pattern if no anomalies
    if (!_lackOfMovement &&
        !_erraticShaking &&
        !_rapidImpact &&
        !_collapsePattern) {
      if (magnitude > 5.0) {
        _movementPattern = 'Active Movement';
      } else if (magnitude > 1.0) {
        _movementPattern = 'Normal Activity';
      } else {
        _movementPattern = 'Resting';
      }
    }
  }

  bool _checkForFreeFall() {
    if (_accelerometerBuffer.length < 10) return false;

    // Check last 10 readings for near-zero acceleration (free fall)
    final recentData = _accelerometerBuffer.sublist(
      _accelerometerBuffer.length - 10,
    );

    int freeFallCount = 0;
    for (var data in recentData) {
      if (data.magnitude < freeThreshold) {
        freeFallCount++;
      }
    }

    // If at least 5 out of 10 readings show free fall
    return freeFallCount >= 5;
  }

  // Simulate heart rate (replace with actual sensor data if available)
  void updateHeartRate(double rate) {
    _heartRate = rate;
    notifyListeners();
  }

  // Trigger automatic emergency alert with cooldown
  void _triggerAutomaticEmergency(EventType eventType) {
    // Check if we're in cooldown period
    if (_lastEmergencyAlert != null) {
      final timeSinceLastAlert = DateTime.now()
          .difference(_lastEmergencyAlert!)
          .inSeconds;
      if (timeSinceLastAlert < emergencyAlertCooldown) {
        debugPrint(
          '⏳ Emergency alert on cooldown (${emergencyAlertCooldown - timeSinceLastAlert}s remaining)',
        );
        return;
      }
    }

    // Update last alert time
    _lastEmergencyAlert = DateTime.now();

    // Call the emergency callback
    debugPrint(
      '🚨 AUTOMATIC EMERGENCY ALERT TRIGGERED: ${eventType.toString()}',
    );
    onEmergencyDetected?.call(eventType);
  }

  // Allow manual reset of emergency state
  void resetEmergencyState() {
    _fallDetected = false;
    _inFreefall = false;
    _freefallStartTime = null;
    _rapidImpact = false;
    _collapsePattern = false;
    _lackOfMovement = false;
    _erraticShaking = false;
    // Clear cooldown when user manually cancels (they confirmed they're okay)
    _lastEmergencyAlert = null;
    debugPrint('✅ Emergency state reset - cooldown cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
