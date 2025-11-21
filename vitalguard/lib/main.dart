import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/sensor_service.dart';
import 'services/emergency_service.dart';
import 'services/background_service.dart';
import 'services/ml_fall_detection_service.dart';
import 'screens/home_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/sos_page.dart';
import 'screens/contacts_page.dart';
import 'utils/app_theme.dart';
import 'models/event_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await BackgroundMonitoringService.initialize();

  runApp(const VitalGuardApp());
}

// Add this widget to handle foreground task
class VitalGuardApp extends StatefulWidget {
  const VitalGuardApp({super.key});

  @override
  State<VitalGuardApp> createState() => _VitalGuardAppState();
}

class _VitalGuardAppState extends State<VitalGuardApp> {
  late SensorService sensorService;
  late EmergencyService emergencyService;
  late MLFallDetectionService mlFallDetectionService;

  @override
  void initState() {
    super.initState();
    sensorService = SensorService();
    emergencyService = EmergencyService();
    mlFallDetectionService = MLFallDetectionService();

    // DISABLED: Rule-based sensor detection (using ML-based detection only)
    // sensorService.onEmergencyDetected = (eventType) {
    //   debugPrint('🚨 Emergency detected by rule-based sensors: $eventType');
    //   emergencyService.triggerEmergencyAlert(eventType);
    // };

    // Set up ML-based fall detection callback
    mlFallDetectionService.onFallDetected = (fallType) {
      debugPrint('🧠 ML Fall detected: $fallType');
      emergencyService.triggerEmergencyAlert(EventType.fall);
    };

    // Listen for background service events
    _setupBackgroundListener();

    // Start background monitoring
    _startBackgroundMonitoring();

    // Initialize and start ML monitoring
    _initializeMLMonitoring();
  }

  Future<void> _initializeMLMonitoring() async {
    final initialized = await mlFallDetectionService.initialize();
    if (initialized) {
      debugPrint('🧠 ML Fall Detection initialized successfully');
      // Start ML monitoring automatically
      await mlFallDetectionService.startMonitoring();
    } else {
      debugPrint(
        '⚠️ ML Fall Detection initialization failed - using rule-based only',
      );
    }
  }

  void _setupBackgroundListener() {
    FlutterForegroundTask.addTaskDataCallback((data) {
      // Cast data to Map<String, dynamic>
      final mapData = data as Map<dynamic, dynamic>;
      if (mapData['action'] == 'emergency_detected') {
        debugPrint('🚨 Emergency detected in background!');
        emergencyService.triggerEmergencyAlert(EventType.fall);
      }
    });
  }

  Future<void> _startBackgroundMonitoring() async {
    final started = await BackgroundMonitoringService.startService();
    if (started) {
      debugPrint('✅ Background monitoring active');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sensorService),
          ChangeNotifierProvider.value(value: emergencyService),
          ChangeNotifierProvider.value(value: mlFallDetectionService),
        ],
        child: MaterialApp(
          title: 'VitalGuard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/dashboard': (context) => const DashboardPage(),
            '/sos': (context) => const SOSPage(),
            '/contacts': (context) => const ContactsPage(),
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    sensorService.dispose();
    emergencyService.dispose();
    mlFallDetectionService.dispose();
    super.dispose();
  }
}
