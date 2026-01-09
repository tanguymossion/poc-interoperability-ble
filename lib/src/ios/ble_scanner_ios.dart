import 'dart:async';

import 'package:objective_c/objective_c.dart' as objc;

import '../ble_scanner.dart';
import 'corebluetooth_bindings.dart';

/// Implémentation iOS du scanner BLE utilisant CoreBluetooth via FFI.
///
/// Utilise les bindings générés par ffigen pour accéder directement
/// aux APIs CoreBluetooth natives d'iOS.
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

  @override
  Future<bool> initialize() async {
    try {
      // Créer le delegate avec les callbacks
      // Utiliser implementAsListener pour éviter les deadlocks
      // car les callbacks sont appelés depuis le thread principal iOS
      _delegate = CBCentralManagerDelegate$Builder.implementAsListener(
        centralManagerDidUpdateState_: _onStateUpdated,
        centralManager_didDiscoverPeripheral_advertisementData_RSSI_:
            _onDeviceDiscovered,
      );

      // Créer le CBCentralManager avec le delegate
      _centralManager = CBCentralManager.alloc().initWithDelegate(
        _delegate,
        queue: null, // Utilise la main queue
      );

      // Attendre que CoreBluetooth initialise le manager (polling)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _updateStateFromManager();
        if (_state != BleScannerState.uninitialized) {
          break;
        }
      }

      return _state == BleScannerState.ready;
    } catch (e) {
      _state = BleScannerState.unavailable;
      return false;
    }
  }

  /// Met à jour l'état du scanner en fonction de l'état du CBCentralManager.
  void _updateStateFromManager() {
    if (_centralManager == null) {
      _state = BleScannerState.unavailable;
      return;
    }

    try {
      final managerState = _centralManager!.state;

      switch (managerState.value) {
        case 0: // CBManagerStateUnknown
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
    } catch (_) {
      _state = BleScannerState.unavailable;
    }
  }

  /// Callback appelé quand l'état du Bluetooth change.
  void _onStateUpdated(CBCentralManager manager) {
    _updateStateFromManager();
  }

  /// Callback appelé pour chaque périphérique découvert.
  void _onDeviceDiscovered(
    CBCentralManager central,
    CBPeripheral peripheral,
    objc.NSDictionary advertisementData,
    objc.NSNumber rssi,
  ) {
    try {
      // Obtenir l'UUID via CBUUID
      final nsuuid = peripheral.identifier;
      final cbuuid = CBUUID.UUIDWithNSUUID(nsuuid);
      final identifier = cbuuid.UUIDString.toDartString();

      // Le nom du périphérique
      final nameNSString = peripheral.name;
      final name = nameNSString?.toDartString() ?? 'Unknown';

      // RSSI
      final rssiValue = rssi.intValue;

      final device = BleDevice(
        identifier: identifier,
        name: name,
        rssi: rssiValue,
        advertisementData: null,
      );

      _devicesController.add(device);
    } catch (_) {
      // Ignorer les erreurs de parsing
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
        _centralManager!.state.value == 5; // == CBManagerStatePoweredOn
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
      if (e is BleScanException) rethrow;
      throw BleScanException('Erreur de scan: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (_centralManager != null && _state == BleScannerState.scanning) {
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
    _scanTimer?.cancel();
    stopScan();
    _devicesController.close();
    _centralManager = null;
    _delegate = null;
    _state = BleScannerState.uninitialized;
  }
}
