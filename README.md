# RehabCoach — Flutter App (Phase 8)
## Real-Time Exercise Quality Classification for Stroke Rehabilitation

**Group 15 — Final Year Project**

---

## Overview

A cross-platform Flutter app (Android & iOS) that connects to an ESP32 IMU sensor via BLE and classifies exercise quality in real-time using a pre-trained Random Forest model deployed via ONNX — fully on-device, no server required.

---

## Architecture

```
ESP32 (MPU-6050)
  │  BLE (Nordic UART, 50 Hz, 36-byte packets)
  ▼
Flutter App
  ├── BleManager          — scan / connect / parse IMU frames
  ├── FeatureExtractor    — 424-feature sliding window (10 s)
  ├── InferenceEngine     — ONNX Random Forest inference
  ├── RecommendationsEngine — coaching tips from config JSON
  └── RehabSessionProvider — app state (Provider)
       │
       ├── HomeScreen      — connect, start/stop, live chart
       ├── FeedbackScreen  — quality badge + coaching tips
       ├── HistoryScreen   — past sessions + distribution
       └── SettingsScreen  — exercise selector + app info
```

---

## Quality Labels

| Model Output | App Label              | Colour |
|---|---|---|
| GOOD         | Good Exercise Quality  | 🟢 Green |
| WARNING      | Needs Improvement      | 🟡 Amber |
| POOR         | Poor Exercise Quality  | 🔴 Red   |

---

## Project Structure

```
stroke_rehab_app/
├── lib/
│   ├── main.dart
│   ├── theme/app_theme.dart          ← design system
│   ├── models/
│   │   ├── imu_frame.dart
│   │   ├── exercise_quality_result.dart
│   │   └── session_record.dart
│   ├── services/
│   │   ├── ble_manager.dart          ← BLE + IMU parsing
│   │   ├── feature_extractor.dart    ← 424 features
│   │   ├── inference_engine.dart     ← ONNX inference
│   │   └── recommendations_engine.dart
│   ├── providers/
│   │   └── rehab_session_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── feedback_screen.dart
│   │   ├── history_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── quality_badge.dart
│       ├── recommendation_card.dart
│       ├── live_chart_widget.dart
│       └── sensor_status_bar.dart
├── assets/
│   ├── models/
│   │   └── model_random_forest_opset12.onnx  ← RF model
│   ├── config/
│   │   └── recommendations.json              ← coaching tips
│   └── fonts/
│       └── Outfit-*.ttf                      ← download below
├── android/app/src/main/AndroidManifest.xml
└── ios/Runner/Info.plist
```

---

## Setup Instructions

### 1. Download Outfit Font
```bash
# Download from Google Fonts and place in assets/fonts/
# https://fonts.google.com/specimen/Outfit
# Required files: Outfit-Regular.ttf, Outfit-Medium.ttf,
#                 Outfit-SemiBold.ttf, Outfit-Bold.ttf
mkdir -p stroke_rehab_app/assets/fonts
```

### 2. Scaffold the Flutter project
```bash
cd "stroke_rehab_app"
flutter create . --project-name stroke_rehab_app --platforms android,ios
# Then restore the lib/ files (do NOT overwrite them)
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Flash ESP32
Open `esp32_firmware/imu_ble.ino` in Arduino IDE.
- Install: `ESP32 BLE Arduino` library
- Board: ESP32 Dev Module
- Flash and confirm serial output shows `Advertising as: RehabCoach-S1`

### 5. Run the app
```bash
flutter run
```

---

## BLE Packet Format

| Bytes | Field   | Unit   |
|-------|---------|--------|
| 0–3   | accel X | m/s²   |
| 4–7   | accel Y | m/s²   |
| 8–11  | accel Z | m/s²   |
| 12–15 | gyro X  | rad/s  |
| 16–19 | gyro Y  | rad/s  |
| 20–23 | gyro Z  | rad/s  |
| 24–35 | mag XYZ | 0 (MPU-6050 has no magnetometer) |

---

## Model Info

| Property       | Value                              |
|----------------|------------------------------------|
| Algorithm      | Random Forest (100 trees)          |
| Features       | 424 (accel, gyro, angles, spectral)|
| Classes        | GOOD / WARNING / POOR              |
| Accuracy       | 83.82%                             |
| Format         | ONNX opset 12                      |
| File           | model_random_forest_opset12.onnx   |
| Inference time | 1–5 ms on-device                   |

---

## Phases Completed

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Exploratory Data Analysis | ✅ |
| 2 | Feature Engineering (424 features) | ✅ |
| 3 | Random Forest Training | ✅ |
| 4 | Feature Importance Analysis | ✅ |
| 5 | Recommendations Engine | ✅ |
| 6 | Model Quantisation (int8) | ✅ |
| 7 | Multi-model Comparison + ONNX Export | ✅ |
| **8** | **Flutter Mobile App** | ✅ |
