# VitalGuard - Low-Level Design (LLD)

## 1. Mobile Application
- **Platform:** Flutter (cross-platform) with Kivy for Python-based sensor handling if needed
- **Modules:**
  - **Sensor Manager:** Collect accelerometer, gyroscope, microphone, GPS data
  - **AI Engine Interface:** Loads TensorFlow Lite models for inference
  - **Local Storage:** SQLite/Hive for event logs
  - **Alert Manager:** Handles vibration, sound, SMS, emergency call triggers
  - **UI Dashboard:** Shows real-time vitals and event history

## 2. Sensor Data Acquisition
- **Accelerometer & Gyroscope:** 50–100 Hz sampling, preprocessing with normalization & sliding windows
- **Microphone:** Audio capture at 16kHz, convert to spectrogram for breathing analysis
- **Heart Rate via Palm Contact:** Detect pulse from accelerometer vibration
- **Optional Camera:** Measure HR via photoplethysmography

## 3. ML Models

### 3.1 Fall Detection
- Input: Accelerometer + Gyroscope time-series
- Model: 1D CNN / LSTM
- Output: Binary fall/no-fall
- Alert triggered if no user response within 15s

### 3.2 Breathing Anomaly Detection
- Input: Microphone audio segments
- Preprocessing: Spectrogram generation
- Model: CNN/LSTM classifier for normal vs abnormal breathing

### 3.3 Heart Rate / Cardiac Arrest Detection
- Input: Accelerometer (palm/phone) + Microphone (breathing)
- Model: Regression for HR estimation + anomaly classifier
- Cardiac arrest alert if HR drops or breathing ceases

## 4. Alert System
- Local vibration and sound (15s acknowledgment window)
- Auto SMS / Call to emergency contacts
- Payload includes:
  - Event type (Fall, Breathing Anomaly, Cardiac Arrest)
  - GPS location
  - Timestamp
  - Optional audio snippet

## 5. Offline-First Architecture
- AI inference fully on-device (TensorFlow Lite)
- Event logging in local database
- Optional cloud sync for analytics / model improvement

## 6. APIs (Optional Cloud via FastAPI)
- **POST /events:** Push detected event to cloud
- **GET /history:** Fetch past events for analytics
- **POST /model_update:** Fetch updated ML models

## 7. Data Flow Diagram



## 8. Security & Privacy
- Local processing whenever possible
- Encrypt local storage and cloud transmission (AES-256 / HTTPS)
- Minimal personal info shared with contacts

## 9. Performance Considerations
- Low-power continuous sensor polling
- On-device AI inference optimized with TensorFlow Lite
- Background/foreground service for 24/7 monitoring

## 10. Tech Stack
- Mobile: Flutter/Kivy
- ML: TensorFlow Lite (trained in Python/TensorFlow)
- Backend (optional): FastAPI
- Database: SQLite/Hive
- Notifications: SMS API / Android/iOS local notifications / emergency calls

## 11. Testing & Validation
- Unit tests for sensor acquisition
- Offline ML inference validation
- End-to-end simulation of falls, breathing, cardiac events
- Alert delivery testing (SMS, call, vibration)

## 12. Summary
LLD provides complete implementation guidance, covering sensors, ML models, offline operation, alerts, storage, and optional cloud integration for VitalGuard.
