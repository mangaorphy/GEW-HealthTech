# VitalGuard - Quick Start Guide

## 🚀 Running the App

### First Time Setup

1. **Navigate to the project directory**
   ```bash
   cd /Users/cococe/Desktop/GEW-HealthTech/vitalguard
   ```

2. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```

3. **Get dependencies** (already done)
   ```bash
   flutter pub get
   ```

4. **Run the app**
   
   For iOS Simulator:
   ```bash
   flutter run -d ios
   ```
   
   For Android Emulator:
   ```bash
   flutter run -d android
   ```
   
   For connected device:
   ```bash
   flutter run
   ```

## 📱 App Navigation

### Home Screen
- View app introduction and features
- Click **"Start Monitoring"** to go to dashboard
- Click **"Learn More"** for additional information

### Dashboard Screen
- Monitor real-time system status
- View Fall Detection, Heart Rate, and Movement Tracking
- Click **"Simulate Fall Detection"** to test the system
- Click **"Emergency SOS"** to access emergency features

### SOS Screen
- Long-press the red SOS button to trigger emergency alert
- View and manage emergency contacts
- 15-second countdown before alerts are sent
- Cancel at any time by clicking "I'm OK"

## 🔧 Testing Features

### Test Fall Detection
1. Go to Dashboard
2. Click "Simulate Fall Detection"
3. A dialog will appear showing fall detected
4. Choose to:
   - Click "I'm OK" to dismiss
   - Click "Send Alert" to trigger emergency flow

### Test Manual SOS
1. Navigate to Emergency SOS page
2. Long-press the red circular SOS button
3. Countdown begins immediately
4. Cancel with "Cancel Alert" button if needed

## ⚙️ Customization

### Change Emergency Contacts

Edit `lib/services/emergency_service.dart`:

```dart
void _loadDefaultContacts() {
  _contacts = [
    EmergencyContact(
      name: 'Emergency Services',
      phoneNumber: '911',
      isEmergencyServices: true,
    ),
    EmergencyContact(
      name: 'Your Name Here',
      phoneNumber: '+1 XXX XXX XXXX',
    ),
  ];
}
```

### Adjust Fall Detection Sensitivity

Edit `lib/services/sensor_service.dart`:

```dart
// For more sensitive detection (detects lighter falls)
static const double fallThreshold = 25.0;
static const double freeThreshold = 2.5;

// For less sensitive detection (only heavy falls)
static const double fallThreshold = 35.0;
static const double freeThreshold = 1.5;
```

## 🐛 Troubleshooting

### Sensors Not Working
- Ensure you're running on a physical device (simulators have limited sensor support)
- Check that sensor permissions are granted
- Try restarting the app

### Location Not Available
- Enable location services on your device
- Grant location permission when prompted
- For iOS: Settings > Privacy > Location Services
- For Android: Settings > Apps > VitalGuard > Permissions

### Calls/SMS Not Working
- Grant phone and SMS permissions
- Ensure you have a SIM card or carrier service
- Test on a physical device (simulators can't make real calls)

## 📊 Project Statistics

- **3 Screens**: Home, Dashboard, SOS
- **2 Services**: Sensor monitoring, Emergency alerts
- **3 Models**: SensorData, EmergencyContact, EventLog
- **8+ Dependencies**: For sensors, location, calls, state management

## 🔄 Development Workflow

### Hot Reload
Press `r` in terminal while app is running to see changes instantly

### Hot Restart  
Press `R` in terminal to fully restart the app

### Debug Mode
```bash
flutter run --debug
```

### Release Build
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📝 Next Steps

1. ✅ Basic app structure completed
2. ✅ Fall detection implemented
3. ✅ Emergency alert system working
4. ⏳ Add cardiac monitoring (heart rate via camera)
5. ⏳ Implement breathing detection
6. ⏳ Add background service for 24/7 monitoring
7. ⏳ Create event log database
8. ⏳ Add cloud sync capabilities

## 🎯 Current Limitations

- Heart rate is simulated (not using actual sensors yet)
- No background service (monitoring stops when app closes)
- Emergency contacts are hardcoded (no UI to add/edit)
- No event history/logs stored yet
- TensorFlow Lite models not integrated

## 💡 Tips

- Test on a real device for accurate sensor data
- Keep the app in foreground for now (background service coming)
- Grant all permissions for full functionality
- Customize emergency contacts before real-world use

---

**Happy Coding!** 🎉

For questions or issues, refer to the main README.md or project documentation.
