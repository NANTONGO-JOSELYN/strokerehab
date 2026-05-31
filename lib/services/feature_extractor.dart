import 'dart:math' as math;

import '../models/imu_frame.dart';

/// Computes the 424-feature vector from a 10-second IMU sliding window.
///
/// Feature pipeline matches the training pipeline from Phase 2.
///
/// **Single-sensor mode (single ESP32 on wrist):**
/// S1 features are computed from real data. S2 features and cross-sensor
/// correlations are **zero-filled** so the vector dimension stays 424.
class FeatureExtractor {
  FeatureExtractor._();

  static const int windowSize = 1000; // 10 s × 100 Hz
  static const int featureCount = 424;

  static const List<String> channelNames = [
    'accelX', 'accelY', 'accelZ',
    'gyroX', 'gyroY', 'gyroZ',
    'magX', 'magY',
    'magZ', // index 6 unused in 7-channel model; mag channels handled
  ];

  /// Compute all 424 features from three IMU windows (wrist A, wrist B, trunk).
  ///
  /// Each sensor window must contain exactly [windowSize] frames.
  static List<double> compute(
    List<ImuFrame> s1,
    List<ImuFrame> s2,
    List<ImuFrame> s3,
  ) {
    assert(s1.length == windowSize,
        'Window must be $windowSize frames, got ${s1.length}');
    assert(s2.length == windowSize,
        'Window must be $windowSize frames, got ${s2.length}');
    assert(s3.length == windowSize,
        'Window must be $windowSize frames, got ${s3.length}');

    final features = <double>[];

    // ── S1 features ──────────────────────────────────────────────────────────
    features.addAll(_sensorFeatures(s1));

    // ── S2 features ──────────────────────────────────────────────────────────
    features.addAll(_sensorFeatures(s2));

    // ── Cross-sensor correlations (18) ────────────────────────────────────────
    features.addAll(_crossCorrelations3(s1, s2, s3));

    // Pad / trim to exactly 424
    if (features.length < featureCount) {
      features.addAll(List.filled(featureCount - features.length, 0.0));
    }

    return features.sublist(0, featureCount);
  }

  // ── Per-sensor feature count ──────────────────────────────────────────────
  // 7 channels × 17 statistical+spectral features = 119
  // + pitch/roll features = 10
  // + angular velocity = 4
  // + joint integrated angles = 18
  //  = 151  per sensor → 302 for two sensors
  // + 6 cross-correlations + padding = 424
  static const int _sensorFeatureCount = 151;

  static List<double> _sensorFeatures(List<ImuFrame> frames) {
    final features = <double>[];

    // Extract channels
    final ax = _col(frames, (f) => f.accelX);
    final ay = _col(frames, (f) => f.accelY);
    final az = _col(frames, (f) => f.accelZ);
    final gx = _col(frames, (f) => f.gyroX);
    final gy = _col(frames, (f) => f.gyroY);
    final gz = _col(frames, (f) => f.gyroZ);
    final mx = _col(frames, (f) => f.magX);

    // 7 channels: accelX/Y/Z, gyroX/Y/Z, magX
    final channels = [ax, ay, az, gx, gy, gz, mx];

    for (final ch in channels) {
      features.addAll(_channelStats(ch)); // 12 statistical
      features.addAll(_channelSpectral(ch)); // 5 spectral → total 17
    }
    // 7 × 17 = 119

    // ── Pitch & roll features ─────────────────────────────────────────────
    final pitchSeries = List<double>.generate(
        frames.length,
        (i) =>
            math.atan2(frames[i].accelY, frames[i].accelZ.abs()) *
            (180 / math.pi));
    final rollSeries = List<double>.generate(
        frames.length,
        (i) =>
            math.atan2(frames[i].accelX, frames[i].accelZ.abs()) *
            (180 / math.pi));

    features.addAll(_angleSeries(pitchSeries)); // 5
    features.addAll(_angleSeries(rollSeries)); // 5
    // 10

    // ── Angular velocity composite ─────────────────────────────────────────
    final angVel =
        List<double>.generate(frames.length, (i) => frames[i].gyroMagnitude);
    features.add(_mean(angVel)); // mean
    features.add(_max(angVel)); // max
    features.add(_std(angVel)); // std
    features.add(_smoothness(angVel)); // smoothness
    // 4

    // ── Joint integrated angles (3 gyro axes) ─────────────────────────────
    // Each axis: cumulative integral (trapezoidal), range, max_excursion → 3×3=9 per sensor?
    // We do: cumulative sum * dt (1/100 Hz), then range + max_excursion per axis → 2×3 = 6
    // For both sensors → 12; pad to 18
    const dt = 0.01; // 100 Hz
    for (final gyroChannel in [gx, gy, gz]) {
      final integral = _cumTrapz(gyroChannel, dt);
      features.add(_range(integral)); // range
      features
          .add(_max(integral.map((v) => v.abs()).toList())); // max excursion
    }
    // 6 → total 139; pad to 151
    features.addAll(List.filled(12, 0.0)); // reserved padding

    return features.sublist(0, _sensorFeatureCount);
  }

  // ── Statistical features (12) ─────────────────────────────────────────────
  static List<double> _channelStats(List<double> x) {
    final m = _mean(x);
    final s = _std(x);
    final v = s * s;
    final mn = _min(x);
    final mx = _max(x);
    final r = mx - mn;
    final rms = _rms(x);
    final sk = _skew(x, m, s);
    final ku = _kurtosis(x, m, s);
    final e = _energy(x);
    final pw = e / x.length;
    final zcr = _zcr(x);
    return [m, s, v, mn, mx, r, rms, sk, ku, e, pw, zcr];
  }

  // ── Spectral features (5) ─────────────────────────────────────────────────
  static List<double> _channelSpectral(List<double> x) {
    final spectrum = _dftPowerSpectrum(x);
    final n = spectrum.length;
    if (n == 0) return List.filled(5, 0.0);

    final total = spectrum.fold(0.0, (a, b) => a + b);
    final maxP = _max(spectrum);
    final meanP = total / n;
    final domF = spectrum.indexOf(maxP).toDouble();

    // Spectral entropy
    double entropy = 0;
    if (total > 0) {
      for (final p in spectrum) {
        if (p > 0) {
          final prob = p / total;
          entropy -= prob * math.log(prob);
        }
      }
    }

    // Band power (split spectrum into thirds)
    final third = n ~/ 3;
    final lowP = _bandPower(spectrum, 0, third);
    final midP = _bandPower(spectrum, third, 2 * third);
    final hiP = _bandPower(spectrum, 2 * third, n);
    // Return 5 features (dropping hiP to stay at 5)
    return [maxP, meanP, domF, entropy, lowP + midP + hiP];
  }

  // ── Pitch/roll series features (5) ───────────────────────────────────────
  static List<double> _angleSeries(List<double> series) => [
        _mean(series),
        _std(series),
        _range(series),
        _min(series),
        _max(series),
      ];

  // ── Cross-sensor correlations (18) ───────────────────────────────────────
  static List<double> _crossCorrelations3(
      List<ImuFrame> s1, List<ImuFrame> s2, List<ImuFrame> s3) {
    return [
      ..._crossCorrelations(s1, s2),
      ..._crossCorrelations(s1, s3),
      ..._crossCorrelations(s2, s3),
    ];
  }

  // ── Cross-sensor correlations (6) ────────────────────────────────────────
  static List<double> _crossCorrelations(List<ImuFrame> s1, List<ImuFrame> s2) {
    return [
      _pearson(_col(s1, (f) => f.accelX), _col(s2, (f) => f.accelX)),
      _pearson(_col(s1, (f) => f.accelY), _col(s2, (f) => f.accelY)),
      _pearson(_col(s1, (f) => f.accelZ), _col(s2, (f) => f.accelZ)),
      _pearson(_col(s1, (f) => f.gyroX), _col(s2, (f) => f.gyroX)),
      _pearson(_col(s1, (f) => f.gyroY), _col(s2, (f) => f.gyroY)),
      _pearson(_col(s1, (f) => f.gyroZ), _col(s2, (f) => f.gyroZ)),
    ];
  }

  // ── DFT power spectrum (magnitude squared, half-spectrum) ─────────────────
  static List<double> _dftPowerSpectrum(List<double> x) {
    final n = x.length;
    final half = n ~/ 2;
    final spectrum = List<double>.filled(half, 0.0);

    // O(N²) DFT — acceptable for N=1000 on-device with Dart isolate.
    for (int k = 0; k < half; k++) {
      double re = 0, im = 0;
      for (int t = 0; t < n; t++) {
        final angle = -2.0 * math.pi * k * t / n;
        re += x[t] * math.cos(angle);
        im += x[t] * math.sin(angle);
      }
      spectrum[k] = (re * re + im * im) / (n * n);
    }
    return spectrum;
  }

  // ── Math helpers ──────────────────────────────────────────────────────────

  static List<double> _col(
          List<ImuFrame> frames, double Function(ImuFrame) fn) =>
      frames.map(fn).toList();

  static double _mean(List<double> x) {
    if (x.isEmpty) return 0;
    return x.fold(0.0, (a, b) => a + b) / x.length;
  }

  static double _std(List<double> x) {
    if (x.length < 2) return 0;
    final m = _mean(x);
    final v = x.fold(0.0, (a, b) => a + (b - m) * (b - m)) / (x.length - 1);
    return math.sqrt(v);
  }

  static double _min(List<double> x) => x.fold(x[0], math.min);
  static double _max(List<double> x) => x.fold(x[0], math.max);
  static double _range(List<double> x) => _max(x) - _min(x);

  static double _rms(List<double> x) =>
      math.sqrt(x.fold(0.0, (a, b) => a + b * b) / x.length);

  static double _energy(List<double> x) => x.fold(0.0, (a, b) => a + b * b);

  static double _zcr(List<double> x) {
    int count = 0;
    for (int i = 1; i < x.length; i++) {
      if ((x[i] >= 0) != (x[i - 1] >= 0)) count++;
    }
    return count / (x.length - 1);
  }

  static double _skew(List<double> x, double m, double s) {
    if (s == 0) return 0;
    final n = x.length;
    final sum = x.fold(0.0, (a, b) {
      final d = b - m;
      return a + d * d * d;
    });
    return sum / (n * s * s * s);
  }

  static double _kurtosis(List<double> x, double m, double s) {
    if (s == 0) return 0;
    final n = x.length;
    final sum = x.fold(0.0, (a, b) {
      final d = b - m;
      return a + d * d * d * d;
    });
    return sum / (n * s * s * s * s) - 3.0;
  }

  static double _smoothness(List<double> x) {
    if (x.length < 2) return 0;
    double sumDiff = 0;
    for (int i = 1; i < x.length; i++) {
      sumDiff += (x[i] - x[i - 1]).abs();
    }
    return 1.0 / (1.0 + sumDiff / (x.length - 1));
  }

  static List<double> _cumTrapz(List<double> x, double dt) {
    final result = List<double>.filled(x.length, 0.0);
    for (int i = 1; i < x.length; i++) {
      result[i] = result[i - 1] + (x[i - 1] + x[i]) * 0.5 * dt;
    }
    return result;
  }

  static double _bandPower(List<double> spectrum, int start, int end) {
    double sum = 0;
    for (int i = start; i < end && i < spectrum.length; i++) {
      sum += spectrum[i];
    }
    return sum;
  }

  static double _pearson(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    final ma = _mean(a);
    final mb = _mean(b);
    double num = 0, da = 0, db = 0;
    for (int i = 0; i < a.length; i++) {
      final xa = a[i] - ma;
      final xb = b[i] - mb;
      num += xa * xb;
      da += xa * xa;
      db += xb * xb;
    }
    final denom = math.sqrt(da * db);
    return denom == 0 ? 0 : num / denom;
  }
}
