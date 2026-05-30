import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/imu_frame.dart';

/// BLE device name advertised by the ESP32 firmware.
const String kRehabCoachDeviceName = 'RehabCoach-S1';

const List<String> kRehabCoachSensorIds = [
  'wrist_a',
  'wrist_b',
  'trunk',
];

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
  // ── Streams ─────────────────────────────────────────────────────────────
  final StreamController<BleConnectionState> _stateCtrl =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<ImuFrame> _framesCtrl =
      StreamController<ImuFrame>.broadcast();
  final StreamController<Map<String, bool>> _sensorStatusCtrl =
      StreamController<Map<String, bool>>.broadcast();

  BleConnectionState _state = BleConnectionState.idle;
  String _deviceName = '';

  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, BluetoothCharacteristic> _txChars = {};
  final Map<String, String> _deviceIdToSensorId = {};
  final Map<String, bool> _sensorStatuses = {
    'wrist_a': false,
    'wrist_b': false,
    'trunk': false,
  };

  StreamSubscription<List<ScanResult>>? _scanSub;
  final List<StreamSubscription<BluetoothConnectionState>> _connSubs = [];
  final List<StreamSubscription<List<int>>> _notifySubs = [];

  Stream<BleConnectionState> get connectionState => _stateCtrl.stream;
  Stream<ImuFrame> get imuFrames => _framesCtrl.stream;
  Stream<Map<String, bool>> get sensorStatus => _sensorStatusCtrl.stream;
  String get connectedDeviceName => _deviceName;
  bool get isConnected => _sensorStatuses.values.any((connected) => connected);

  // ── Permissions ─────────────────────────────────────────────────────────
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

  // ── Connect ─────────────────────────────────────────────────────────────
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
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.platformName != kRehabCoachDeviceName) continue;
        if (_deviceIdToSensorId.containsKey(r.device.id.id)) continue;
        if (_deviceIdToSensorId.length >= kRehabCoachSensorIds.length) continue;

        final sensorId = kRehabCoachSensorIds[_deviceIdToSensorId.length];
        _deviceIdToSensorId[r.device.id.id] = sensorId;

        await _connectDevice(r.device, sensorId);

        if (_sensorStatuses.values.where((connected) => connected).length ==
            kRehabCoachSensorIds.length) {
          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();
          return;
        }
      }
    });

    Future.delayed(const Duration(seconds: 16), () {
      if (_state == BleConnectionState.scanning &&
          !_sensorStatuses.values.any((connected) => connected)) {
        _setState(BleConnectionState.error);
      }
    });
  }

  Future<void> _connectDevice(BluetoothDevice device, String sensorId) async {
    _setState(BleConnectionState.connecting);
    _devices[sensorId] = device;

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _deviceName = 'Tri-sensor RehabCoach';

      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();
          if (uuid.contains('6e400003') || characteristic.properties.notify) {
            _txChars[sensorId] = characteristic;
            await characteristic.setNotifyValue(true);
            final notifySub = characteristic.onValueReceived.listen(
              (bytes) => _onBytes(bytes, sensorId),
            );
            _notifySubs.add(notifySub);
            break;
          }
        }
        if (_txChars.containsKey(sensorId)) break;
      }

      _setSensorStatus(sensorId, true);
      if (_state != BleConnectionState.connected) {
        _setState(BleConnectionState.connected);
      }

      final connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _setSensorStatus(sensorId, false);
          _devices.remove(sensorId);
          _txChars.remove(sensorId);

          if (!_sensorStatuses.values.any((connected) => connected)) {
            _deviceName = '';
            _setState(BleConnectionState.idle);
            _scheduleReconnect();
          }
        }
      });
      _connSubs.add(connSub);
    } catch (e) {
      _setSensorStatus(sensorId, false);
      _devices.remove(sensorId);
      _txChars.remove(sensorId);
      if (!_sensorStatuses.values.any((connected) => connected)) {
        _deviceName = '';
        _setState(BleConnectionState.error);
      }
    }
  }

  // ── Frame parsing ──────────────────────────────────────────────────────
  void _onBytes(List<int> bytes, String sensorId) {
    if (bytes.length < 24) return;

    try {
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      final frame = ImuFrame(
        accelX: data.getFloat32(0, Endian.little),
        accelY: data.getFloat32(4, Endian.little),
        accelZ: data.getFloat32(8, Endian.little),
        gyroX: data.getFloat32(12, Endian.little),
        gyroY: data.getFloat32(16, Endian.little),
        gyroZ: data.getFloat32(20, Endian.little),
        magX: bytes.length >= 28 ? data.getFloat32(24, Endian.little) : 0,
        magY: bytes.length >= 32 ? data.getFloat32(28, Endian.little) : 0,
        magZ: bytes.length >= 36 ? data.getFloat32(32, Endian.little) : 0,
        sensorId: sensorId,
        timestamp: DateTime.now(),
      );
      if (!_framesCtrl.isClosed) {
        _framesCtrl.add(frame);
      }
    } catch (e) {
      // Ignore malformed packets.
    }
  }

  void _setSensorStatus(String sensorId, bool connected) {
    if (_sensorStatuses[sensorId] == connected) return;
    _sensorStatuses[sensorId] = connected;
    if (!_sensorStatusCtrl.isClosed) {
      _sensorStatusCtrl.add(Map.unmodifiable(_sensorStatuses));
    }
  }

  // ── Auto reconnect ──────────────────────────────────────────────────────
  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_state == BleConnectionState.idle) {
        connect();
      }
    });
  }

  // ── Disconnect ─────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _scanSub?.cancel();
    _scanSub = null;

    for (final sub in _notifySubs) {
      await sub.cancel();
    }
    _notifySubs.clear();

    for (final sub in _connSubs) {
      await sub.cancel();
    }
    _connSubs.clear();

    for (final device in _devices.values) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _devices.clear();
    _txChars.clear();
    _deviceIdToSensorId.clear();
    _deviceName = '';

    for (final sensorId in _sensorStatuses.keys) {
      _sensorStatuses[sensorId] = false;
    }
    if (!_sensorStatusCtrl.isClosed) {
      _sensorStatusCtrl.add(Map.unmodifiable(_sensorStatuses));
    }

    _setState(BleConnectionState.idle);
  }

  // ── Dispose ───────────────────────────────────────────────────────────
  void dispose() {
    disconnect();
    _stateCtrl.close();
    _framesCtrl.close();
    _sensorStatusCtrl.close();
  }

  // ── Helper ─────────────────────────────────────────────────────────────
  void _setState(BleConnectionState state) {
    _state = state;
    if (!_stateCtrl.isClosed) {
      _stateCtrl.add(state);
    }
  }
}
