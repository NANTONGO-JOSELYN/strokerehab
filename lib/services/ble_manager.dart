import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/imu_frame.dart';

/// BLE device name advertised by the ESP32 firmware.
const String kRehabCoachDeviceName = 'RehabCoach-S1';

/// Nordic UART Service UUID (matches ESP32 firmware).
const String kNordicUartServiceUuid =
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

const String kNordicUartTxUuid =
    '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

/// Overall BLE connection state exposed to the UI.
enum BleConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  error,
}

/// Manages BLE scanning, GATT connection, and IMU frame streaming.
class BleManager {

  // ── State ────────────────────────────────────────────────────────────────
  final StreamController<BleConnectionState> _stateCtrl =
      StreamController<BleConnectionState>.broadcast();

  final StreamController<ImuFrame> _framesCtrl =
      StreamController<ImuFrame>.broadcast();

  BleConnectionState _state = BleConnectionState.idle;

  String _deviceName = '';

  Stream<BleConnectionState> get connectionState => _stateCtrl.stream;

  Stream<ImuFrame> get imuFrames => _framesCtrl.stream;

  String get connectedDeviceName => _deviceName;

  bool get isConnected => _state == BleConnectionState.connected;

  // ── Private ──────────────────────────────────────────────────────────────
  BluetoothDevice? _device;

  BluetoothCharacteristic? _txChar;

  StreamSubscription<List<ScanResult>>? _scanSub;

  StreamSubscription<BluetoothConnectionState>? _connSub;

  StreamSubscription<List<int>>? _notifySub;

  // ── Permissions ──────────────────────────────────────────────────────────
  Future<bool> _requestPermissions() async {

    if (Platform.isAndroid) {

      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      return results.values.every((s) => s.isGranted);
    }

    return true;
  }

  // ── Connect ──────────────────────────────────────────────────────────────
  Future<void> connect() async {

    if (_state == BleConnectionState.connected ||
        _state == BleConnectionState.scanning ||
        _state == BleConnectionState.connecting) {
      return;
    }

    final granted = await _requestPermissions();

    if (!granted) {
      _setState(BleConnectionState.error);
      return;
    }

    _setState(BleConnectionState.scanning);

    await _scanSub?.cancel();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    _scanSub = FlutterBluePlus.scanResults.listen(
      (results) async {

        for (final r in results) {

          if (r.device.platformName == kRehabCoachDeviceName) {

            await FlutterBluePlus.stopScan();

            await _scanSub?.cancel();

            await _connectDevice(r.device);

            return;
          }
        }
      },
    );

    // Timeout
    Future.delayed(
      const Duration(seconds: 16),
      () {
        if (_state == BleConnectionState.scanning) {
          _setState(BleConnectionState.error);
        }
      },
    );
  }

  Future<void> _connectDevice(BluetoothDevice device) async {

    _setState(BleConnectionState.connecting);

    _device = device;

    try {

      await device.connect(
        timeout: const Duration(seconds: 10),
      );

      _deviceName = device.platformName;

      final services = await device.discoverServices();

      for (final service in services) {

        for (final characteristic in service.characteristics) {

          final uuid =
              characteristic.uuid.toString().toLowerCase();

          if (uuid.contains('6e400003') ||
              characteristic.properties.notify) {

            _txChar = characteristic;

            await characteristic.setNotifyValue(true);

            _notifySub = characteristic.onValueReceived.listen(
              _onBytes,
            );

            break;
          }
        }

        if (_txChar != null) break;
      }

      _setState(BleConnectionState.connected);

      // Monitor disconnects
      _connSub = device.connectionState.listen(
        (state) {

          if (state ==
              BluetoothConnectionState.disconnected) {

            _deviceName = '';

            _setState(BleConnectionState.idle);

            _scheduleReconnect();
          }
        },
      );

    } catch (e) {

      _deviceName = '';

      _setState(BleConnectionState.error);
    }
  }

  // ── Frame parsing ────────────────────────────────────────────────────────
  void _onBytes(List<int> bytes) {

    if (bytes.length < 24) return;

    try {

      final data = ByteData.sublistView(
        Uint8List.fromList(bytes),
      );

      final frame = ImuFrame(
        accelX: data.getFloat32(0, Endian.little),
        accelY: data.getFloat32(4, Endian.little),
        accelZ: data.getFloat32(8, Endian.little),

        gyroX: data.getFloat32(12, Endian.little),
        gyroY: data.getFloat32(16, Endian.little),
        gyroZ: data.getFloat32(20, Endian.little),

        magX: bytes.length >= 28
            ? data.getFloat32(24, Endian.little)
            : 0,

        magY: bytes.length >= 32
            ? data.getFloat32(28, Endian.little)
            : 0,

        magZ: bytes.length >= 36
            ? data.getFloat32(32, Endian.little)
            : 0,

        sensorId: 's1',

        timestamp:
            DateTime .now(),
      );

      if (!_framesCtrl.isClosed) {
        _framesCtrl.add(frame);
      }

    } catch (e) {
      // Ignore malformed packets
    }
  }

  // ── Auto reconnect ───────────────────────────────────────────────────────
  void _scheduleReconnect() {

    Future.delayed(
      const Duration(seconds: 4),
      () {

        if (_state == BleConnectionState.idle) {
          connect();
        }
      },
    );
  }

  // ── Disconnect ───────────────────────────────────────────────────────────
  Future<void> disconnect() async {

    await _scanSub?.cancel();

    await _notifySub?.cancel();

    await _connSub?.cancel();

    await _device?.disconnect();

    _device = null;

    _txChar = null;

    _deviceName = '';

    _setState(BleConnectionState.idle);
  }

  // ── Dispose ──────────────────────────────────────────────────────────────
  void dispose() {

    disconnect();

    _stateCtrl.close();

    _framesCtrl.close();
  }

  // ── Helper ───────────────────────────────────────────────────────────────
  void _setState(BleConnectionState state) {

    _state = state;

    if (!_stateCtrl.isClosed) {
      _stateCtrl.add(state);
    }
  }
}