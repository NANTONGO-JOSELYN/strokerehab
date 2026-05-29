import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/exercise_quality_result.dart';
import '../theme/app_theme.dart';

/// Web stub for [InferenceEngine].
///
/// The onnxruntime package depends on dart:ffi which cannot be compiled
/// for the web.  This no-op implementation allows the app to compile
/// and run on web, though real-time ML inference will not be available.
class InferenceEngine {
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    // No-op: ONNX Runtime is not available on the web.
    _ready = false;
  }

  Future<ExerciseQualityResult> classify(List<double> features) async {
    // Return a neutral fallback — no model inference possible on web.
    return ExerciseQualityResult(
      quality: QualityLevel.needsImprovement,
      confidence: 0.0,
      probabilities: [0.34, 0.33, 0.33],
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _ready = false;
  }
}