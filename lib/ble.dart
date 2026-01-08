/// Package BLE cross-platform utilisant FFI/JNI pour accéder aux APIs natives.
///
/// Ce package fournit une API unifiée pour le scan BLE sur Android et iOS.
///
/// ## API haut niveau (recommandée)
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
/// - **Android** : ✅ Fonctionnel via JNI (jnigen)
/// - **iOS** : 🚧 En cours (CoreBluetooth FFI)
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
        // Scanner BLE (nouvelle API)
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
        // Callback pour le scan
        // ignore: camel_case_types
        BluetoothAdapter$LeScanCallback,
        // ignore: camel_case_types
        $BluetoothAdapter$LeScanCallback;

// ============================================================================
// API BAS NIVEAU - iOS (CoreBluetooth)
// TEMPORAIREMENT DÉSACTIVÉ - les exports causent le chargement des symboles
// ============================================================================
// TODO: Réactiver quand les trampolines seront correctement compilés
// export 'src/ios/corebluetooth_bindings.dart' show ...;
