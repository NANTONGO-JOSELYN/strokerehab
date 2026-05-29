import 'dart:typed_data';

/// A single 9-DOF IMU sample decoded from a BLE notification packet.
///
/// The ESP32 transmits a 36-byte packet (9 × float32, little-endian):
///   [accelX, accelY, accelZ, gyroX, gyroY, gyroZ, magX, magY, magZ]
class ImuFrame {
  /// Which sensor produced this frame: 's1' (wrist) or 's2' (trunk / zero-filled).
  final String sensorId;

  // ── Accelerometer (g) ─────────────────────────────
  final double accelX;
  final double accelY;
  final double accelZ;

  // ── Gyroscope (°/s) ───────────────────────────────
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  // ── Magnetometer (µT) ─────────────────────────────
  final double magX;
  final double magY;
  final double magZ;

  /// Wall-clock time the frame was received (not transmitted).
  final DateTime timestamp;

  const ImuFrame({
    required this.sensorId,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magX,
    required this.magY,
    required this.magZ,
    required this.timestamp,
  });

  /// Creates a zero-filled frame for a missing sensor (S2 when using single board).
  factory ImuFrame.zero({required String sensorId}) => ImuFrame(
        sensorId: sensorId,
        accelX: 0, accelY: 0, accelZ: 0,
        gyroX: 0, gyroY: 0, gyroZ: 0,
        magX: 0, magY: 0, magZ: 0,
        timestamp: DateTime.now(),
      );

  /// Decode raw BLE bytes (36-byte little-endian float32 array).
  factory ImuFrame.fromBytes(List<int> bytes, {required String sensorId}) {
    if (bytes.length < 36) {
      return ImuFrame.zero(sensorId: sensorId);
    }

    double f(int offset) {
      final bd = ByteData.sublistView(Uint8List.fromList(bytes), offset, offset + 4);
      return bd.getFloat32(0, Endian.little);
    }

    return ImuFrame(
      sensorId: sensorId,
      accelX: f(0),  accelY: f(4),  accelZ: f(8),
      gyroX:  f(12), gyroY:  f(16), gyroZ:  f(20),
      magX:   f(24), magY:   f(28), magZ:   f(32),
      timestamp: DateTime.now(),
    );
  }

  /// Accelerometer magnitude (g).
  double get accelMagnitude => _mag3(accelX, accelY, accelZ);

  /// Gyroscope magnitude (°/s).
  double get gyroMagnitude => _mag3(gyroX, gyroY, gyroZ);

  static double _mag3(double x, double y, double z) {
    final v = x * x + y * y + z * z;
    if (v <= 0) return 0;
    // Newton-Raphson sqrt (avoids dart:math in model layer)
    double r = v;
    double s = 1.0;
    while ((r - s).abs() > 1e-7) {
      r = (r + s) / 2;
      s = v / r;
    }
    return r;
  }

  List<double> toList() => [
        accelX, accelY, accelZ,
        gyroX,  gyroY,  gyroZ,
        magX,   magY,   magZ,
      ];

  @override
  String toString() =>
      'ImuFrame($sensorId a=[${accelX.toStringAsFixed(2)},'
      '${accelY.toStringAsFixed(2)},${accelZ.toStringAsFixed(2)}])';
}
