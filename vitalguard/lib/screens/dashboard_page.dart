import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/sensor_service.dart';
import '../services/emergency_service.dart';
import '../models/event_log.dart';
import '../utils/app_theme.dart';
import '../widgets/auto_emergency_notification.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  OverlayEntry? _emergencyOverlay;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Start monitoring when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;

      final sensorService = Provider.of<SensorService>(context, listen: false);
      final emergencyService = Provider.of<EmergencyService>(
        context,
        listen: false,
      );

      if (!sensorService.isMonitoring) {
        sensorService.startMonitoring();
      }

      // Listen for emergency service state changes
      emergencyService.addListener(_onEmergencyStateChanged);
    });
  }

  void _onEmergencyStateChanged() {
    if (!mounted || _isDisposed) return;

    final emergencyService = Provider.of<EmergencyService>(
      context,
      listen: false,
    );

    if (emergencyService.isAlertActive && _emergencyOverlay == null) {
      _showEmergencyOverlay();
    } else if (!emergencyService.isAlertActive && _emergencyOverlay != null) {
      _hideEmergencyOverlay();
    }
  }

  void _showEmergencyOverlay() {
    if (!mounted || _isDisposed) return;

    _emergencyOverlay = OverlayEntry(
      builder: (context) => Consumer<EmergencyService>(
        builder: (context, service, child) {
          if (!service.isAlertActive) {
            return const SizedBox.shrink();
          }

          return AutoEmergencyNotification(
            eventType:
                service.currentEventType ??
                EventType.fall, // Use actual event type
            countdown: service.countdown,
            onCancel: () {
              if (!mounted || _isDisposed) return;
              service.cancelAlert();
              try {
                final sensorService = Provider.of<SensorService>(
                  context,
                  listen: false,
                );
                sensorService.resetEmergencyState();
              } catch (e) {
                debugPrint('Error resetting sensor state: $e');
              }
            },
          );
        },
      ),
    );

    try {
      Overlay.of(context).insert(_emergencyOverlay!);
    } catch (e) {
      debugPrint('Error inserting overlay: $e');
      _emergencyOverlay = null;
    }
  }

  void _hideEmergencyOverlay() {
    _emergencyOverlay?.remove();
    _emergencyOverlay = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideEmergencyOverlay();

    try {
      final emergencyService = Provider.of<EmergencyService>(
        context,
        listen: false,
      );
      emergencyService.removeListener(_onEmergencyStateChanged);
    } catch (e) {
      debugPrint('Error removing listener: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.02),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Live Monitoring',
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Dashboard',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBlue.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtitle
              Text(
                'Real-time health and safety monitoring',
                style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Status Banner
              Consumer<SensorService>(
                builder: (context, sensorService, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sensorService.isMonitoring
                              ? 'All Systems Operational'
                              : 'Monitoring Disabled',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Monitoring Cards
              Consumer<SensorService>(
                builder: (context, sensorService, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMonitoringCard(
                          icon: Icons.personal_injury_outlined,
                          iconColor: Colors.blue,
                          title: 'Fall Detection',
                          status: sensorService.isMonitoring
                              ? 'Active'
                              : 'Inactive',
                          statusColor: sensorService.isMonitoring
                              ? AppTheme.successGreen
                              : AppTheme.greyText,
                          subtitle: 'Accelerometer monitoring enabled',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMonitoringCard(
                          icon: Icons.favorite_outline,
                          iconColor: Colors.pink,
                          title: 'Heart Rate',
                          status: '${sensorService.heartRate.toInt()} BPM',
                          statusColor: AppTheme.successGreen,
                          subtitle: 'Within normal range',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              Consumer<SensorService>(
                builder: (context, sensorService, child) {
                  return _buildAdvancedSensorCard(sensorService);
                },
              ),

              const SizedBox(height: 40),

              // Fall Detection Demo Section
              _buildDemoSection(context),

              const SizedBox(height: 32),

              // Emergency SOS Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/sos');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningRed,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                icon: const Icon(Icons.phone, size: 24),
                label: const Text(
                  'Emergency SOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    required Color statusColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSensorCard(SensorService sensorService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.sensors, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Advanced Sensor Analysis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Movement Pattern Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPatternColor(sensorService).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPatternColor(sensorService).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getPatternIcon(sensorService),
                  color: _getPatternColor(sensorService),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorService.movementPattern,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _getPatternColor(sensorService),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Magnitude: ${sensorService.currentMagnitude.toStringAsFixed(2)} m/s²',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sensor Indicators Grid
          Row(
            children: [
              Expanded(
                child: _buildSensorIndicator(
                  'No Movement',
                  sensorService.lackOfMovement,
                  Icons.accessibility_new,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSensorIndicator(
                  'Erratic Shake',
                  sensorService.erraticShaking,
                  Icons.vibration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSensorIndicator(
                  'Rapid Impact',
                  sensorService.rapidImpact,
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSensorIndicator(
                  'Collapse Pattern',
                  sensorService.collapsePattern,
                  Icons.trending_down,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sensor Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSensorRow(
                  'Accelerometer',
                  '${sensorService.currentMagnitude.toStringAsFixed(2)} m/s²',
                ),
                const Divider(height: 16),
                _buildSensorRow(
                  'Gyroscope',
                  '${sqrt(pow(sensorService.gyroscopeX, 2) + pow(sensorService.gyroscopeY, 2) + pow(sensorService.gyroscopeZ, 2)).toStringAsFixed(2)} rad/s',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorIndicator(String label, bool active, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.warningRed.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppTheme.warningRed : Colors.grey.shade300,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: active ? AppTheme.warningRed : AppTheme.greyText,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppTheme.warningRed : AppTheme.greyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Color _getPatternColor(SensorService sensorService) {
    if (sensorService.rapidImpact || sensorService.collapsePattern) {
      return AppTheme.warningRed;
    }
    if (sensorService.erraticShaking || sensorService.lackOfMovement) {
      return Colors.orange;
    }
    return AppTheme.successGreen;
  }

  IconData _getPatternIcon(SensorService sensorService) {
    if (sensorService.rapidImpact) return Icons.warning_amber_rounded;
    if (sensorService.collapsePattern) return Icons.trending_down;
    if (sensorService.erraticShaking) return Icons.vibration;
    if (sensorService.lackOfMovement) return Icons.accessibility_new;
    return Icons.check_circle;
  }

  Widget _buildDemoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Fall Detection Technology',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Experience our AI-powered fall detection system',
            style: TextStyle(fontSize: 14, color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Demo Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successGreen,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'System Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitoring for sudden movements',
                  style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Simulate Fall Button
          OutlinedButton.icon(
            onPressed: () {
              _simulateFall(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: AppTheme.primaryBlue),
            ),
            icon: Icon(Icons.play_arrow, color: AppTheme.primaryBlue),
            label: Text(
              'Simulate Fall Detection',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateFall(BuildContext context) {
    final emergencyService = Provider.of<EmergencyService>(
      context,
      listen: false,
    );

    // Show fall detected dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warningRed),
            const SizedBox(width: 12),
            const Text('Fall Detected!'),
          ],
        ),
        content: const Text(
          'A fall has been detected. Emergency alert will be sent in 15 seconds unless cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('I\'m OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              emergencyService.triggerEmergencyAlert(EventType.fall);
              Navigator.pushNamed(context, '/sos');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}
