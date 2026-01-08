import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:objective_c/objective_c.dart' as objc;

import '../ble_scanner.dart';
import 'corebluetooth_bindings.dart';

/// Implémentation iOS du scanner BLE utilisant CoreBluetooth via FFI.
class BleScannerIOS implements BleScanner {
  BleScannerState _state = BleScannerState.uninitialized;
  final _devicesController = StreamController<BleDevice>.broadcast();

  CBCentralManager? _centralManager;
  CBCentralManagerDelegate? _delegate;
  Completer<void>? _scanCompleter;
  Timer? _scanTimer;

  @override
  BleScannerState get state => _state;

  @override
  Stream<BleDevice> get discoveredDevices => _devicesController.stream;

  /// Message de debug pour diagnostiquer les problèmes
  String? debugMessage;

  @override
  Future<bool> initialize() async {
    try {
      debugMessage = 'Création du delegate...';
      debugPrint('BleScannerIOS: Création du delegate...');

      // Créer le delegate avec les callbacks
      // IMPORTANT: Utiliser implementAsListener pour éviter les deadlocks
      // car les callbacks sont appelés depuis le thread principal iOS
      _delegate = CBCentralManagerDelegate$Builder.implementAsListener(
        centralManagerDidUpdateState_: _onStateUpdated,
        centralManager_didDiscoverPeripheral_advertisementData_RSSI_:
            _onDeviceDiscovered,
      );

      debugMessage = 'Delegate créé, création du CBCentralManager...';
      debugPrint(
        'BleScannerIOS: Delegate créé, création du CBCentralManager...',
      );

      // Créer le CBCentralManager avec le delegate
      _centralManager = CBCentralManager.alloc().initWithDelegate(
        _delegate,
        queue: null, // Utilise la main queue
      );

      debugMessage = 'CBCentralManager créé, polling de l\'état...';
      debugPrint('BleScannerIOS: CBCentralManager créé, polling de l\'état...');

      // Attendre que CoreBluetooth initialise le manager
      // et polling pour vérifier l'état
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _updateStateFromManager();
        debugPrint('BleScannerIOS: Polling #$i, state=$_state');
        if (_state != BleScannerState.uninitialized) {
          break;
        }
      }

      debugMessage = 'Initialisation terminée, state=$_state';
      debugPrint('BleScannerIOS: Initialisation terminée. State: $_state');
      return _state == BleScannerState.ready;
    } catch (e, stackTrace) {
      debugMessage = 'Erreur d\'initialisation: $e';
      debugPrint('BleScannerIOS initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      _state = BleScannerState.unavailable;
      return false;
    }
  }

  void _updateStateFromManager() {
    if (_centralManager == null) {
      _state = BleScannerState.unavailable;
      return;
    }

    try {
      final managerState = _centralManager!.state;
      debugPrint(
        'BleScannerIOS: CBManagerState raw value: ${managerState.value}',
      );

      switch (managerState.value) {
        case 0: // CBManagerStateUnknown
          _state = BleScannerState.uninitialized;
          break;
        case 1: // CBManagerStateResetting
          _state = BleScannerState.uninitialized;
          break;
        case 2: // CBManagerStateUnsupported
          _state = BleScannerState.unavailable;
          break;
        case 3: // CBManagerStateUnauthorized
          _state = BleScannerState.unauthorized;
          break;
        case 4: // CBManagerStatePoweredOff
          _state = BleScannerState.disabled;
          break;
        case 5: // CBManagerStatePoweredOn
          _state = BleScannerState.ready;
          break;
        default:
          _state = BleScannerState.unavailable;
      }
    } catch (e) {
      debugPrint('BleScannerIOS: Error reading state: $e');
      _state = BleScannerState.unavailable;
    }
  }

  void _onStateUpdated(CBCentralManager manager) {
    debugPrint('BleScannerIOS: Callback centralManagerDidUpdateState appelé');
    _updateStateFromManager();
  }

  void _onDeviceDiscovered(
    CBCentralManager central,
    CBPeripheral peripheral,
    objc.NSDictionary advertisementData,
    objc.NSNumber rssi,
  ) {
    try {
      // Obtenir l'UUID via CBUUID - utiliser toDartString() pour convertir NSString
      final nsuuid = peripheral.identifier;
      final cbuuid = CBUUID.UUIDWithNSUUID(nsuuid);
      final identifier = cbuuid.UUIDString.toDartString();

      // Le nom via NSString - utiliser toDartString()
      final nameNSString = peripheral.name;
      final name = nameNSString?.toDartString() ?? 'Unknown';

      // RSSI
      final rssiValue = rssi.intValue;

      debugPrint(
        'BleScannerIOS: Découvert: $name ($identifier) RSSI: $rssiValue',
      );

      final device = BleDevice(
        identifier: identifier,
        name: name,
        rssi: rssiValue,
        advertisementData: null,
      );

      _devicesController.add(device);
    } catch (e, stack) {
      debugPrint('BleScannerIOS: Erreur découverte: $e');
      debugPrint('BleScannerIOS: Stack: $stack');
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    return _centralManager != null &&
        _centralManager!.state.value != 2; // != CBManagerStateUnsupported
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return _centralManager != null &&
        _centralManager!.state.value == 5; // CBManagerStatePoweredOn
  }

  @override
  Future<bool> startScan({Duration? duration}) async {
    if (_state != BleScannerState.ready) {
      throw BleScanException('Scanner non prêt. État actuel: $_state');
    }

    if (_centralManager == null) {
      throw BleScanException('CBCentralManager non initialisé');
    }

    try {
      debugPrint('BleScannerIOS: Démarrage du scan...');

      // Scanner tous les périphériques (nil = pas de filtre par service)
      _centralManager!.scanForPeripheralsWithServices(null, options: null);
      _state = BleScannerState.scanning;

      if (duration != null) {
        _scanCompleter = Completer<void>();
        _scanTimer = Timer(duration, () {
          if (_state == BleScannerState.scanning) {
            stopScan();
          }
        });
        await _scanCompleter!.future;
      }

      return true;
    } catch (e) {
      debugPrint('BleScannerIOS: Erreur de scan: $e');
      if (e is BleScanException) rethrow;
      throw BleScanException('Erreur de scan: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (_centralManager != null && _state == BleScannerState.scanning) {
      debugPrint('BleScannerIOS: Arrêt du scan...');
      _centralManager!.stopScan();
      _state = BleScannerState.ready;
    }

    if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
      _scanCompleter!.complete();
    }
    _scanCompleter = null;
  }

  @override
  void dispose() {
    debugPrint('BleScannerIOS: Dispose...');
    _scanTimer?.cancel();
    stopScan();
    _devicesController.close();
    _centralManager = null;
    _delegate = null;
    _state = BleScannerState.uninitialized;
  }
}
