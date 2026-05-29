import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../models/exercise_quality_result.dart';
import '../theme/app_theme.dart';

/// FFI-backed ONNX inference engine.
///
/// Compiled only on native platforms (dart:io is available).
/// The onnxruntime package depends on dart:ffi which cannot be
/// compiled for the web.
class InferenceEngine {
  OrtSession? _session;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      final modelBytes =
          await rootBundle.load('assets/models/model_random_forest_opset12.onnx');
      final modelData = modelBytes.buffer.asUint8List();
      OrtEnv.instance.init();
      final opts = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelData, opts);
      _ready = true;
    } catch (e) {
      _ready = false;
    }
  }

  Future<ExerciseQualityResult> classify(List<double> features) async {
    if (!_ready || _session == null || features.length != 424) {
      return _fallback();
    }

    try {
      final input = Float32List.fromList(features);
      final tensor = OrtValueTensor.createTensorWithDataList(input, [1, 424]);
      final runOpts = OrtRunOptions();
      final outputs = _session!.run(runOpts, {'X': tensor});

      final rawLabelVal = (outputs[0]?.value as List?)?.first;
      final probOutput = outputs[1]?.value;

      tensor.release();
      runOpts.release();

      final rawLabel = rawLabelVal is int
          ? rawLabelVal
          : int.tryParse(rawLabelVal.toString()) ?? 1;

      final quality = _qualityFromInt(rawLabel);

      final probs = <double>[0.0, 0.0, 0.0];
      if (probOutput is Map) {
        for (final entry in probOutput.entries) {
          final cls = int.tryParse(entry.key.toString()) ?? 0;
          final prob = (entry.value as num).toDouble();
          if (cls >= 0 && cls < 3) probs[cls] = prob;
        }
      }

      final confidence = probs[rawLabel.clamp(0, 2)];

      return ExerciseQualityResult(
        quality: quality,
        confidence: confidence.clamp(0.0, 1.0),
        probabilities: probs,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return _fallback();
    }
  }

  void dispose() {
    _session?.release();
    _session = null;
    _ready = false;
  }

  static QualityLevel _qualityFromInt(int v) {
    switch (v) {
      case 1:
        return QualityLevel.good;
      case 2:
        return QualityLevel.needsImprovement;
      default:
        return QualityLevel.poor;
    }
  }

  static ExerciseQualityResult _fallback() => ExerciseQualityResult(
        quality: QualityLevel.needsImprovement,
        confidence: 0.0,
        probabilities: [0.0, 0.0, 1.0],
        timestamp: DateTime.now(),
      );
}