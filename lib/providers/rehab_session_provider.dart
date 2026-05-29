import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stroke_rehab_app/theme/app_theme.dart';

import '../models/exercise_quality_result.dart';
import '../models/imu_frame.dart';
import '../models/session_record.dart';
import '../services/ble_manager.dart';
import '../services/feature_extractor.dart';
import '../services/inference_engine.dart';
import '../services/recommendations_engine.dart';

/// The exercises supported by the app (mapped from Phase 5 config).
const List<String> kExerciseNames = [
  'Shoulder Flexion',
  'Elbow Extension',
  'Wrist Rotation',
  'Hip Abduction',
  'Knee Extension',
  'Ankle Dorsiflexion',
];

/// App-wide state managed by [ChangeNotifier] / Provider.
///
/// Lifecycle:
///   IDLE → connectAndStart() → CONNECTING → CONNECTED → session active
///   stopSession() → IDLE
class RehabSessionProvider extends ChangeNotifier {
  // ── Services ──────────────────────────────────────────────────────────────
  final BleManager _ble = BleManager();
  late InferenceEngine _inferenceEngine;
  late RecommendationsEngine _recsEngine;

  // ── Connection state ──────────────────────────────────────────────────────
  BleConnectionState _connectionState = BleConnectionState.idle;
  BleConnectionState get connectionState => _connectionState;
  
  bool _isSimulated = false;
  bool get isSimulated => _isSimulated;

  bool _wristConnected = false;
  bool get wristConnected => _wristConnected || (connectionState == BleConnectionState.connected && !_isSimulated);

  bool _lowerBackConnected = false;
  bool get lowerBackConnected => _lowerBackConnected || (connectionState == BleConnectionState.connected && !_isSimulated);

  bool get isConnected => (connectionState == BleConnectionState.connected) || (_wristConnected && _lowerBackConnected);

  String _deviceName = '';
  String get deviceName => _deviceName;

  void simulateConnect() {
    _connectionState = BleConnectionState.connected;
    _isSimulated = true;
    _wristConnected = true;
    _lowerBackConnected = true;
    _deviceName = 'Dual-sensor setup (Simulated)';
    _frameCount = 120;
    notifyListeners();
  }

  // ── Session state ─────────────────────────────────────────────────────────
  bool _sessionActive = false;
  bool get sessionActive => _sessionActive;

  int _selectedExerciseIndex = 0;
  int get selectedExerciseIndex => _selectedExerciseIndex;
  String get selectedExerciseName => kExerciseNames[_selectedExerciseIndex];

  DateTime? _sessionStart;
  Duration get sessionDuration =>
      _sessionStart == null
          ? Duration.zero
          : DateTime.now().difference(_sessionStart!);

  final List<ImuFrame> _window = [];

  // Static so _onFrame (called from a stream listener) can read it without an
  // instance qualifier. Value comes from FeatureExtractor so there is one
  // source of truth.
 // windowSize is 1000 (10 s × 100 Hz), NOT 50
static const int _windowSize = FeatureExtractor.windowSize; // = 1000
  /// Last 100 frames exposed to chart widgets.
  List<ImuFrame> get chartWindow =>
      _window.length > 100
          ? _window.sublist(_window.length - 100)
          : List.from(_window);

  int _frameCount = 0;
  int get frameCount => _frameCount;

  // ── Inference results ─────────────────────────────────────────────────────
  ExerciseQualityResult? _latestResult;
  ExerciseQualityResult? get latestResult => _latestResult;

  List<Recommendation> _recommendations = [];
  List<Recommendation> get recommendations =>
      List.unmodifiable(_recommendations);

  /// Running history of quality results in the current session.
  final List<ExerciseQualityResult> _sessionResults = [];
  List<ExerciseQualityResult> get sessionResults =>
      List.unmodifiable(_sessionResults);

  // ── Inference timer (runs every 1 s once window is full) ─────────────────
  Timer? _inferenceTimer;

  // ── Persisted history ─────────────────────────────────────────────────────
  List<SessionRecord> _history = [];
  List<SessionRecord> get history => List.unmodifiable(_history);

  // ── Init ──────────────────────────────────────────────────────────────────
  RehabSessionProvider() {
    _init();
  }

  Future<void> _init() async {
    _inferenceEngine = InferenceEngine();
    _recsEngine = RecommendationsEngine();

    await Future.wait([
      _inferenceEngine.init(),
      _recsEngine.init(),
    ]);

    await _loadHistory();

    _ble.connectionState.listen((state) {
      _connectionState = state;
      if (state == BleConnectionState.connected) {
        _deviceName = _ble.connectedDeviceName;
      } else if (state == BleConnectionState.idle ||
          state == BleConnectionState.error) {
        _stopInferenceTimer();
        _sessionActive = false;
      }
      notifyListeners();
    });

    _ble.imuFrames.listen(_onFrame);
  }

  // ── BLE control ───────────────────────────────────────────────────────────
  Future<void> connectAndStart() async => _ble.connect();

  Future<void> disconnect() async {
    _isSimulated = false;
    _wristConnected = false;
    _lowerBackConnected = false;
    _connectionState = BleConnectionState.idle;
    stopSession();
    await _ble.disconnect();
    notifyListeners();
  }

  // ── Session control ───────────────────────────────────────────────────────
  void startSession() {
    if (!isConnected) return;
    _sessionActive = true;
    _sessionStart = DateTime.now();
    _window.clear();
    _sessionResults.clear();
    _latestResult = null;
    _recommendations = [];
    _frameCount = 0;
    _startInferenceTimer();
    notifyListeners();
  }

  Future<void> stopSession() async {
    _stopInferenceTimer();
    final wasActive = _sessionActive;
    _sessionActive = false;

    if (wasActive && _sessionResults.isNotEmpty) {
      final record = SessionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseIndex: _selectedExerciseIndex,
        startTime: _sessionStart!,
        endTime: DateTime.now(),
        results: List.from(_sessionResults),
      );
      _history.insert(0, record);
      await _persistHistory();
    }
    notifyListeners();
  }

  void setExercise(int index) {
    if (_sessionActive) return;
    _selectedExerciseIndex = index.clamp(0, kExerciseNames.length - 1);
    notifyListeners();
  }

  // ── Frame processing ──────────────────────────────────────────────────────
  void _onFrame(ImuFrame frame) {
    _window.add(frame);
    if (_window.length > _windowSize) _window.removeAt(0);
    _frameCount++;
    if (_frameCount % 10 == 0) notifyListeners(); // throttle chart redraws
  }

  // ── Inference timer ───────────────────────────────────────────────────────
  void _startInferenceTimer() {
    _inferenceTimer?.cancel();
    _inferenceTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_window.length < _windowSize) return; // wait for full window
      await _runInference();
    });
  }

  void _stopInferenceTimer() {
    _inferenceTimer?.cancel();
    _inferenceTimer = null;
  }

  Future<void> _runInference() async {
  try {
     final features = FeatureExtractor.compute(List.from(_window));
    final result = await _inferenceEngine.classify(features);
    _latestResult = result;
    _sessionResults.add(result);

    // result.quality is the QualityLevel enum field.
    // result.label is a String (e.g. "Good") — NOT for comparisons.
    // QualityLevel is the correct enum (good, needsImprovement, poor).
    if (result.quality != QualityLevel.good) {
      _recommendations = await _recsEngine.getRecommendations(
        exerciseIndex: _selectedExerciseIndex,
        quality: result.quality,        // QualityLevel, not a String
      );
    } else {
      _recommendations = [];
    }

    notifyListeners();
  } catch (e) {
    debugPrint('[RehabSessionProvider] Inference error: $e');
  }
}
  

  // ── History persistence ───────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('session_history') ?? [];
      _history = raw
          .map((s) =>
              SessionRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _history.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('session_history', raw);
    } catch (_) {}
  }

  Future<void> deleteHistoryRecord(String id) async {
    _history.removeWhere((r) => r.id == id);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _persistHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopInferenceTimer();
    _ble.dispose();
    _inferenceEngine.dispose();
    super.dispose();
  }
}