import 'dart:async';

import 'package:flutter/foundation.dart';
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
  Timer? _scanTimer;

  // Flag pour savoir si on accepte les résultats
  bool _isAcceptingResults = false;

  // Flag pour savoir si le scan natif est actif
  bool _nativeScanActive = false;

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

      // Créer le callback une seule fois
      _scanCallback = BluetoothAdapter$LeScanCallback.implement(
        $BluetoothAdapter$LeScanCallback(onLeScan: _onDeviceFound),
      );

      _state = BleScannerState.ready;
      return true;
    } catch (e) {
      debugPrint('BleScannerAndroid: initialize error: $e');
      _state = BleScannerState.unavailable;
      return false;
    }
  }

  void _onDeviceFound(
    BluetoothDevice? device,
    int rssi,
    JByteArray? scanRecord,
  ) {
    if (!_isAcceptingResults || device == null) return;

    try {
      final address = device.getAddress()?.toDartString() ?? 'Unknown';
      String name = '';
      try {
        name = device.getName()?.toDartString() ?? '';
      } catch (_) {}

      List<int>? advertisementData;
      if (scanRecord != null) {
        advertisementData = List.generate(
          scanRecord.length,
          (i) => scanRecord[i],
        );
      }

      _devicesController.add(
        BleDevice(
          identifier: address,
          name: name,
          rssi: rssi,
          advertisementData: advertisementData,
        ),
      );
    } catch (e) {
      debugPrint('BleScannerAndroid: Error processing device: $e');
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
    debugPrint('BleScannerAndroid: startScan called, state=$_state');

    if (_adapter == null || _scanCallback == null) {
      throw BleScanException('Scanner non initialisé');
    }

    if (_state == BleScannerState.scanning) {
      return true;
    }

    // Démarrer le scan natif si pas déjà actif
    if (!_nativeScanActive) {
      debugPrint('BleScannerAndroid: Starting native scan');
      final started = _adapter!.startLeScan(_scanCallback);
      if (started) {
        _nativeScanActive = true;
        debugPrint('BleScannerAndroid: Scan started successfully');
      } else {
        debugPrint('BleScannerAndroid: startLeScan returned false');
      }
    }

    // Commencer à accepter les résultats
    _isAcceptingResults = true;
    _state = BleScannerState.scanning;

    debugPrint('BleScannerAndroid: Now accepting results');

    if (duration != null) {
      _scanCompleter = Completer<void>();

      _scanTimer?.cancel();
      _scanTimer = Timer(duration, () {
        if (_state == BleScannerState.scanning) {
          stopScan();
        }
      });

      await _scanCompleter!.future;
    }

    return true;
  }

  @override
  Future<void> stopScan() async {
    debugPrint('BleScannerAndroid: stopScan called');

    _scanTimer?.cancel();
    _scanTimer = null;
    _isAcceptingResults = false;
    _state = BleScannerState.ready;

    if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
      _scanCompleter!.complete();
    }
    _scanCompleter = null;
  }

  @override
  void dispose() {
    debugPrint('BleScannerAndroid: dispose called');

    _scanTimer?.cancel();
    _isAcceptingResults = false;

    // Arrêter le scan natif
    if (_nativeScanActive && _adapter != null && _scanCallback != null) {
      try {
        _adapter!.stopLeScan(_scanCallback!);
      } catch (_) {}
      _nativeScanActive = false;
    }

    _devicesController.close();

    try {
      _scanCallback?.release();
    } catch (_) {}
    _scanCallback = null;

    _adapter?.release();
    _adapter = null;
    _state = BleScannerState.uninitialized;
  }
}
