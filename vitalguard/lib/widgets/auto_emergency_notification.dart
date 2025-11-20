import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/event_log.dart';

class AutoEmergencyNotification extends StatelessWidget {
  final EventType eventType;
  final int countdown;
  final VoidCallback onCancel;

  const AutoEmergencyNotification({
    super.key,
    required this.eventType,
    required this.countdown,
    required this.onCancel,
  });

  String get eventName {
    switch (eventType) {
      case EventType.fall:
        return 'FALL DETECTED';
      case EventType.cardiacEvent:
        return 'COLLAPSE DETECTED';
      case EventType.manualSOS:
        return 'EMERGENCY';
      default:
        return 'EMERGENCY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warningRed.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.warningRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: AppTheme.warningRed,
                  ),
                ),

                const SizedBox(height: 24),

                // Event Type
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.warningRed,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'Emergency alert will be sent in',
                  style: TextStyle(fontSize: 16, color: AppTheme.greyText),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Countdown Circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.warningRed, width: 6),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$countdown',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.warningRed,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.greyText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "I'M OKAY - CANCEL ALERT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Tap if you are safe and do not need help',
                  style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
