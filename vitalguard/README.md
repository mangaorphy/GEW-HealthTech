# VitalGuard - AI-Powered Personal Safety Monitor

VitalGuard is an AI-powered mobile application that provides 24/7 health and safety monitoring using smartphone sensors. It detects life-threatening events such as falls, cardiac abnormalities, and breathing issues, then automatically alerts emergency services or designated contacts.

## Features

✅ **Fall Detection** - Real-time monitoring using accelerometer and gyroscope sensors  
✅ **Cardiac Monitoring** - Heart rate tracking and abnormality detection  
✅ **24/7 Protection** - Continuous background monitoring  
✅ **Emergency SOS** - Manual emergency alert with countdown  
✅ **Auto-Alert System** - Automatic emergency contact notification  
✅ **Offline-First** - Works without internet connection  
✅ **Live Dashboard** - Real-time monitoring status display

## Project Structure

```
lib/
├── main.dart                 # App entry point with providers
├── models/
│   ├── emergency_contact.dart # Emergency contact model
│   ├── event_log.dart        # Event logging model
│   └── sensor_data.dart      # Sensor data model
├── screens/
│   ├── home_page.dart        # Landing page
│   ├── dashboard_page.dart   # Live monitoring dashboard
│   └── sos_page.dart         # Emergency SOS screen
├── services/
│   ├── sensor_service.dart   # Sensor monitoring & fall detection
│   └── emergency_service.dart # Emergency alert management
└── utils/
    └── app_theme.dart        # App-wide theme configuration
```

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / Xcode for mobile deployment

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

## Permissions Required

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to send emergency alerts with your position.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need continuous location access for 24/7 monitoring.</string>
```

## How It Works

### Fall Detection Algorithm

1. **Continuous Monitoring**: Accelerometer data collected at ~50Hz
2. **Free Fall Detection**: Checks for near-zero acceleration (< 2 m/s²)
3. **Impact Detection**: Detects sudden high acceleration (> 30 m/s²)
4. **Event Confirmation**: Confirms fall if free-fall precedes impact
5. **Alert Trigger**: 15-second countdown before sending emergency alerts

### Emergency Alert Flow

1. Fall/cardiac event detected OR manual SOS triggered
2. Device vibrates and shows alert dialog
3. 15-second countdown begins
4. User can cancel by pressing "I'm OK"
5. If not cancelled, alerts sent to emergency contacts

## Key Dependencies

- `sensors_plus` - Accelerometer & gyroscope access
- `geolocator` - GPS location for emergency alerts
- `permission_handler` - Runtime permission management
- `url_launcher` - Phone calls and SMS
- `provider` - State management
- `tflite_flutter` - TensorFlow Lite for ML models
- `workmanager` - Background task scheduling

## Configuration

### Customize Emergency Contacts

Edit in `/lib/services/emergency_service.dart`:
```dart
_contacts = [
  EmergencyContact(
    name: 'Emergency Services',
    phoneNumber: '911',
    isEmergencyServices: true,
  ),
  // Add your contacts here
];
```

### Adjust Fall Detection Sensitivity

Modify in `/lib/services/sensor_service.dart`:
```dart
static const double fallThreshold = 30.0; // Impact threshold
static const double freeThreshold = 2.0;  // Free-fall threshold
```

## Testing the App

### Simulate a Fall
1. Navigate to Dashboard
2. Click "Simulate Fall Detection"
3. Choose to cancel or send alert

### Manual SOS
1. Navigate to Emergency SOS page
2. Long-press the red SOS button
3. Alert sends immediately

## Future Enhancements

- [ ] Cardiac arrest detection using camera/microphone
- [ ] Breathing abnormality detection
- [ ] Cloud sync for event history
- [ ] Advanced ML models for better accuracy
- [ ] Family member dashboard
- [ ] Medical history integration

---

**⚠️ Disclaimer**: VitalGuard is an assistive safety tool and should not replace professional medical devices or emergency response systems.

