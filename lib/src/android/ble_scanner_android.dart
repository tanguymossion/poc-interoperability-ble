import 'dart:async';

import 'package:jni/jni.dart';

import '../ble_scanner.dart';
import 'jni_bindings.dart';

/// Implémentation Android du scanner BLE utilisant JNI.
class BleScannerAndroid implements BleScanner {
  BleScannerState _state = BleScannerState.uninitialized;
  final _devicesController = StreamController<BleDevice>.broadcast();

  BluetoothAdapter? _adapter;
  BluetoothAdapter$LeScanCallback? _scanCallback;
  Completer<void>? _scanCompleter;

  @override
  BleScannerState get state => _state;

  @override
  Stream<BleDevice> get discoveredDevices => _devicesController.stream;

  @override
  Future<bool> initialize() async {
    try {
      _adapter = BluetoothAdapter.getDefaultAdapter();

      if (_adapter == null) {
        _state = BleScannerState.unavailable;
        return false;
      }

      if (!_adapter!.isEnabled()) {
        _state = BleScannerState.disabled;
        return false;
      }

      // Créer le callback de scan
      _scanCallback = BluetoothAdapter$LeScanCallback.implement(
        $BluetoothAdapter$LeScanCallback(onLeScan: _onDeviceFound),
      );

      _state = BleScannerState.ready;
      return true;
    } catch (e) {
      _state = BleScannerState.unavailable;
      return false;
    }
  }

  void _onDeviceFound(
    BluetoothDevice? device,
    int rssi,
    JByteArray? scanRecord,
  ) {
    if (device == null) return;

    try {
      final address = device.getAddress()?.toDartString() ?? 'Unknown';
      String name = '';
      try {
        name = device.getName()?.toDartString() ?? '';
      } catch (_) {
        // getName() peut échouer sans permission BLUETOOTH_CONNECT
      }

      List<int>? advertisementData;
      if (scanRecord != null) {
        advertisementData = List.generate(
          scanRecord.length,
          (i) => scanRecord[i],
        );
      }

      final bleDevice = BleDevice(
        identifier: address,
        name: name,
        rssi: rssi,
        advertisementData: advertisementData,
      );

      _devicesController.add(bleDevice);
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    return _adapter != null;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return _adapter?.isEnabled() ?? false;
  }

  @override
  Future<bool> startScan({Duration? duration}) async {
    if (_adapter == null || _scanCallback == null) {
      throw BleScanException('Scanner non initialisé');
    }

    if (_state == BleScannerState.scanning) {
      return true; // Déjà en cours
    }

    try {
      final started = _adapter!.startLeScan(_scanCallback);
      if (!started) {
        throw BleScanException('Échec du démarrage du scan');
      }

      _state = BleScannerState.scanning;

      // Si une duration est spécifiée, attendre la fin du scan
      if (duration != null) {
        _scanCompleter = Completer<void>();

        // Timer pour arrêter le scan après la durée
        Future.delayed(duration, () {
          if (_state == BleScannerState.scanning) {
            stopScan();
          }
        });

        // Attendre que stopScan soit appelé
        await _scanCompleter!.future;
      }

      return true;
    } catch (e) {
      if (e is BleScanException) rethrow;
      throw BleScanException('Erreur de scan: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    if (_state != BleScannerState.scanning) return;

    try {
      if (_adapter != null && _scanCallback != null) {
        _adapter!.stopLeScan(_scanCallback!);
      }
    } catch (_) {
      // Ignorer les erreurs d'arrêt
    }

    _state = BleScannerState.ready;

    // Compléter le Future de startScan si en attente
    if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
      _scanCompleter!.complete();
    }
    _scanCompleter = null;
  }

  @override
  void dispose() {
    stopScan();
    _devicesController.close();
    _scanCallback?.release();
    _adapter?.release();
    _scanCallback = null;
    _adapter = null;
    _state = BleScannerState.uninitialized;
  }
}
