# VitalGuard - High-Level Design (HLD)

## 1. Project Overview
VitalGuard is an AI-powered mobile platform for continuous health monitoring. It detects life-threatening events such as falls, abnormal breathing, and cardiac arrest using only smartphone sensors and automatically alerts emergency services or designated contacts.

**Goals:**
- 24/7 monitoring without user initiation
- Real-time detection of critical health events
- Offline-first functionality
- Measurable impact through automated alerts and event logs

## 2. System Architecture

                     ┌─────────────────────┐
                     │   Mobile Device     │
                     │                     │
                     └─────────┬──────────┘
                               │
              ┌────────────────┴─────────────────┐
              │                                  │
      ┌───────▼───────┐                  ┌───────▼────────┐
      │ Sensor Manager│                  │ AI Detection   │
      │ (Accel, Gyro, │                  │ Engine (TFLite)│
      │ Microphone,   │                  └───────┬────────┘
      │ GPS)          │                          │
      └───────┬───────┘                          │
              │                                  │
              ▼                                  ▼
       ┌─────────────┐                  ┌───────────────┐
       │ Preprocessing│                 │ Local Dashboard│
       └─────────────┘                  └───────────────┘
              │                                  │
              └───────────────┬──────────────────┘
                              ▼
                     ┌─────────────────┐
                     │ Alert Manager   │
                     │ (Vibration, SMS,│
                     │ Calls, Emergency│
                     │ Notifications)  │
                     └─────────┬───────┘
                               │
                               ▼
                     ┌─────────────────┐
                     │ Emergency Contact│
                     │ Authorities      │
                     └─────────────────┘


## 3. Components

1. **Mobile Device:** Android/iOS smartphone running Flutter
2. **Sensors:** Accelerometer, Gyroscope, Microphone, GPS (optional Camera).
3. **AI Detection Engine:** TensorFlow Lite models for falls, abnormal breathing, heart rate, cardiac arrest.
4. **Local Dashboard:** Visualizes real-time vitals, logs events.
5. **Alert System:** Automatic vibration, SMS, call to emergency contacts.
6. **Cloud Sync/Analytics (Optional):** Trend analysis and model improvement.

## 4. Data Flow
1. Sensors collect raw signals continuously.
2. AI Detection Engine processes signals in real-time.
3. Critical events trigger:
   - Device vibration
   - Timer for user acknowledgment (15s)
   - Automatic alert to emergency contacts if no response
4. Events logged locally; optionally synced to cloud.

## 5. Security & Privacy
- Local processing keeps sensitive data on device
- Alerts share minimal information (location + event)
- Optional cloud data anonymized and encrypted

## 6. Technology Stack
- Mobile: Flutter
- Backend (optional): FastAPI
- ML: TensorFlow Lite
- Database (local): SQLite / Hive
- Notifications: SMS / Calls / Local alerts
