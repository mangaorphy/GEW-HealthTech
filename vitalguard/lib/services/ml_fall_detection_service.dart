import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// ML-based Fall Detection Service
/// Uses TensorFlow Lite model to detect falls from sensor data
class MLFallDetectionService extends ChangeNotifier {
  // TensorFlow Lite interpreter
  Interpreter? _interpreter;

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Data collection buffers
  final List<List<double>> _sensorDataBuffer = [];

  // Sampling configuration
  static const int samplingFrequency = 20; // 20 Hz
  static const int windowDurationSeconds = 20; // 20 seconds
  static const int totalSamples =
      samplingFrequency * windowDurationSeconds; // 400 samples
  static const int inputSize =
      totalSamples * 6; // 2400 (400 timesteps × 6 features)

  // Timer for controlled sampling
  Timer? _samplingTimer;

  // Activity class mapping
  static const Map<int, String> activityLabels = {
    0: 'fall', // Forward fall
    1: 'lfall', // Left fall
    2: 'light', // Light activity
    3: 'rfall', // Right fall
    4: 'sit', // Sitting
    5: 'step', // Stepping
    6: 'walk', // Walking
  };

  // Fall detection callback
  Function(String fallType)? onFallDetected;

  // State
  bool _isMonitoring = false;
  String _currentActivity = 'Initializing...';
  double _fallProbability = 0.0;

  // Getters
  bool get isMonitoring => _isMonitoring;
  String get currentActivity => _currentActivity;
  double get fallProbability => _fallProbability;

  /// Initialize the TensorFlow Lite model
  Future<bool> initialize() async {
    try {
      debugPrint('🧠 Loading TensorFlow Lite model...');

      // Load the model from assets
      _interpreter = await Interpreter.fromAsset(
        'models/fall_detection_model.tflite',
      );

      // Verify input/output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('✅ Model loaded successfully');
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');
      debugPrint('   Expected input: (1, $inputSize)');

      // Validate model shape
      if (inputShape[1] != inputSize) {
        debugPrint(
          '⚠️ Warning: Model expects ${inputShape[1]} features, but we provide $inputSize',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error loading ML model: $e');
      return false;
    }
  }

  /// Start continuous real-time monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('⚠️ Monitoring already active');
      return;
    }

    if (_interpreter == null) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ Cannot start monitoring: Model not loaded');
        return;
      }
    }

    _isMonitoring = true;
    _currentActivity = 'Monitoring...';
    notifyListeners();

    debugPrint('🔍 Starting ML-based fall detection monitoring');

    // Subscribe to sensors once (they stay active for all windows)
    _subscribeSensors();

    // Start new data collection window
    _startNewWindow();
  }

  /// Stop monitoring
  void stopMonitoring() {
    debugPrint('⏹️ Stopping ML monitoring');

    _isMonitoring = false;
    _samplingTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _sensorDataBuffer.clear();

    notifyListeners();
  }

  // Temporary storage for last sensor readings (shared across windows)
  List<double>? _lastAccelData;
  List<double>? _lastGyroData;

  /// Subscribe to sensors (done once at start)
  void _subscribeSensors() {
    // Subscribe to accelerometer (high frequency, we'll downsample)
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _lastAccelData = [event.x, event.y, event.z];
      },
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
        _handleSensorError('Accelerometer');
      },
    );

    // Subscribe to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _lastGyroData = [event.x, event.y, event.z];
      },
      onError: (error) {
        debugPrint('❌ Gyroscope error: $error');
        _handleSensorError('Gyroscope');
      },
    );

    debugPrint('📡 Sensor subscriptions active');
  }

  /// Start a new 20-second data collection window
  void _startNewWindow() {
    if (!_isMonitoring) return;

    // Cancel any existing sampling timer
    _samplingTimer?.cancel();

    // Clear previous window data
    _sensorDataBuffer.clear();

    debugPrint('📊 Starting new 20-second data collection window');

    // Timer to sample at exactly 20 Hz (every 50ms)
    _samplingTimer = Timer.periodic(
      Duration(milliseconds: 50), // 1000ms / 20Hz = 50ms
      (timer) {
        // Check if we have both sensor readings
        if (_lastAccelData != null && _lastGyroData != null) {
          // Combine accelerometer (x,y,z) and gyroscope (x,y,z)
          final combinedSample = [..._lastAccelData!, ..._lastGyroData!];

          _sensorDataBuffer.add(combinedSample);

          // Check if we've collected 400 samples (20 seconds at 20 Hz)
          if (_sensorDataBuffer.length >= totalSamples) {
            timer.cancel();
            _processWindow();
          }
        }
      },
    );

    // Safety timeout: If window doesn't complete in 25 seconds, restart
    Timer(Duration(seconds: 25), () {
      if (_sensorDataBuffer.length < totalSamples && _isMonitoring) {
        debugPrint(
          '⚠️ Window timeout - collected ${_sensorDataBuffer.length}/$totalSamples samples',
        );
        _startNewWindow();
      }
    });
  }

  /// Process the collected 20-second window
  Future<void> _processWindow() async {
    try {
      debugPrint(
        '🔬 Processing window with ${_sensorDataBuffer.length} samples',
      );

      // Validate data completeness
      if (_sensorDataBuffer.length < totalSamples) {
        debugPrint(
          '⚠️ Incomplete data: ${_sensorDataBuffer.length}/$totalSamples samples',
        );
        _startNewWindow();
        return;
      }

      // Check if there's actual movement (filter stationary phone)
      if (!_hasSignificantMovement()) {
        debugPrint('😴 Phone stationary - skipping inference to save battery');
        _startNewWindow();
        return;
      }

      // Step 1: Flatten the 2D array (400 samples × 6 features) into 1D array (2400)
      final List<double> flattenedData = [];
      for (var sample in _sensorDataBuffer) {
        flattenedData.addAll(sample);
      }

      debugPrint(
        '📦 Flattened data size: ${flattenedData.length} (expected: $inputSize)',
      );

      // Step 2: Prepare input tensor - shape (1, 2400)
      final input = [flattenedData];

      // Step 3: Prepare output tensor - shape (1, 7) for 7 activity classes
      final output = List.filled(
        1,
        List<double>.filled(7, 0.0),
      ).map((e) => List<double>.from(e)).toList();

      // Step 4: Run inference
      _interpreter!.run(input, output);

      // Step 5: Get prediction results
      final predictions = output[0];

      // Find class with highest probability
      int predictedClassIndex = 0;
      double maxProbability = predictions[0];

      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxProbability) {
          maxProbability = predictions[i];
          predictedClassIndex = i;
        }
      }

      // Step 6: Map to activity label
      final predictedActivity =
          activityLabels[predictedClassIndex] ?? 'unknown';
      _currentActivity = predictedActivity;
      _fallProbability = maxProbability;

      debugPrint(
        '🎯 Prediction: $predictedActivity (confidence: ${(maxProbability * 100).toStringAsFixed(1)}%)',
      );
      debugPrint(
        '   All probabilities: ${predictions.map((p) => (p * 100).toStringAsFixed(1)).join(', ')}',
      );

      // Step 7: Check if fall detected
      final isFall = _isFallActivity(predictedActivity);

      // Require both fall classification AND significant movement variance
      // This reduces false positives from stationary phone or bad model predictions
      if (isFall && maxProbability > 0.85) {
        // Increased to 85% confidence threshold
        debugPrint(
          '🚨 FALL DETECTED: $predictedActivity (${(maxProbability * 100).toStringAsFixed(1)}% confidence)',
        );
        _triggerFallAlert(predictedActivity);
      } else if (isFall) {
        debugPrint(
          '⚠️ Possible fall: $predictedActivity (${(maxProbability * 100).toStringAsFixed(1)}% confidence) - below threshold',
        );
      } else {
        debugPrint('✅ Normal activity: $predictedActivity');
      }

      notifyListeners();

      // Step 8: Start next window for continuous monitoring
      if (_isMonitoring) {
        _startNewWindow();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing window: $e');
      debugPrint('Stack trace: $stackTrace');

      // Retry with new window
      if (_isMonitoring) {
        _startNewWindow();
      }
    }
  }

  /// Check if activity is a fall type
  bool _isFallActivity(String activity) {
    return activity == 'fall' || activity == 'lfall' || activity == 'rfall';
  }

  /// Check if there's significant movement in the collected data
  /// Returns false if phone is stationary (reduces false positives)
  bool _hasSignificantMovement() {
    if (_sensorDataBuffer.isEmpty) return false;

    // Calculate variance of accelerometer data
    double sumAccelX = 0, sumAccelY = 0, sumAccelZ = 0;

    for (var sample in _sensorDataBuffer) {
      sumAccelX += sample[0]; // accel x
      sumAccelY += sample[1]; // accel y
      sumAccelZ += sample[2]; // accel z
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

    // Calculate total variance (movement indicator)
    double totalVariance = varianceX + varianceY + varianceZ;

    // If variance is very low, phone is stationary
    const double minVarianceThreshold = 0.5; // Adjust based on testing

    if (totalVariance < minVarianceThreshold) {
      debugPrint(
        '📍 Movement variance: ${totalVariance.toStringAsFixed(3)} (threshold: $minVarianceThreshold) - STATIONARY',
      );
      return false;
    }

    debugPrint(
      '🏃 Movement variance: ${totalVariance.toStringAsFixed(3)} - MOVING',
    );
    return true;
  }

  /// Trigger fall alert
  void _triggerFallAlert(String fallType) {
    // Call the callback to trigger emergency alert
    onFallDetected?.call(fallType);

    debugPrint('📢 Fall alert triggered for: $fallType');
  }

  /// Handle sensor errors
  void _handleSensorError(String sensorName) {
    debugPrint('⚠️ $sensorName sensor error - restarting window');

    // Cancel current subscriptions
    _samplingTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();

    // Wait a bit and restart if still monitoring
    if (_isMonitoring) {
      Future.delayed(Duration(seconds: 2), () {
        if (_isMonitoring) {
          _startNewWindow();
        }
      });
    }
  }

  /// Get detailed activity breakdown
  Map<String, dynamic> getActivityDetails() {
    return {
      'activity': _currentActivity,
      'probability': _fallProbability,
      'isMonitoring': _isMonitoring,
      'bufferSize': _sensorDataBuffer.length,
      'targetSamples': totalSamples,
    };
  }

  @override
  void dispose() {
    stopMonitoring();
    _interpreter?.close();
    super.dispose();
  }
}
