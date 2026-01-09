/// Package BLE cross-platform utilisant FFI/JNI pour accéder aux APIs natives.
///
/// Ce package fournit une API unifiée pour le scan BLE sur Android et iOS,
/// sans utiliser de Method Channels - uniquement des appels natifs directs.
///
/// ## Utilisation
///
/// ```dart
/// import 'package:my_package_ffi/ble.dart';
///
/// // Créer le scanner (détection automatique de la plateforme)
/// final scanner = createBleScanner();
///
/// // Initialiser
/// await scanner.initialize();
///
/// // Écouter les appareils découverts
/// scanner.discoveredDevices.listen((device) {
///   print('${device.name} (${device.identifier}) - ${device.rssi} dBm');
/// });
///
/// // Scanner pendant 10 secondes
/// await scanner.startScan(duration: Duration(seconds: 10));
///
/// // Ou arrêter manuellement
/// await scanner.stopScan();
///
/// // Libérer les ressources
/// scanner.dispose();
/// ```
///
/// ## Support des plateformes
///
/// - **Android** : via JNI (jnigen) - API `BluetoothAdapter.startLeScan()`
/// - **iOS** : via FFI (ffigen) - CoreBluetooth `CBCentralManager`
library;

// ============================================================================
// API HAUT NIVEAU (cross-platform)
// ============================================================================

export 'src/ble_scanner.dart'
    show BleScanner, BleDevice, BleScannerState, BleScanException, BleUtils;
export 'src/ble_scanner_factory.dart' show createBleScanner;

// Implémentations spécifiques (pour usage avancé)
export 'src/android/ble_scanner_android.dart' show BleScannerAndroid;
export 'src/ios/ble_scanner_ios.dart' show BleScannerIOS;

// ============================================================================
// API BAS NIVEAU - ANDROID (JNI)
// ============================================================================

export 'src/android/jni_bindings.dart'
    show
        // Gestion Bluetooth
        BluetoothManager,
        BluetoothAdapter,
        BluetoothDevice,
        // Scanner BLE
        BluetoothLeScanner,
        ScanResult,
        ScanRecord,
        ScanCallback,
        ScanSettings,
        // ignore: camel_case_types
        ScanSettings$Builder,
        ScanFilter,
        // ignore: camel_case_types
        ScanFilter$Builder,
        // Callback pour le scan (ancienne API)
        // ignore: camel_case_types
        BluetoothAdapter$LeScanCallback,
        // ignore: camel_case_types
        $BluetoothAdapter$LeScanCallback;

// ============================================================================
// API BAS NIVEAU - iOS (CoreBluetooth)
// ============================================================================

export 'src/ios/corebluetooth_bindings.dart'
    show
        // Gestionnaire central
        CBCentralManager,
        CBCentralManagerDelegate,
        // ignore: camel_case_types
        CBCentralManagerDelegate$Builder,
        CBManagerState,
        // Périphérique
        CBPeripheral,
        // UUID
        CBUUID,
        NSUUID;
