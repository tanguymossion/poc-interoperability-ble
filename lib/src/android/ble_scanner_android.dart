/// Scanner BLE Android utilisant directement les classes natives via JNI.
///
/// Ce fichier réexporte les bindings générés par jnigen pour une utilisation
/// directe des APIs Android BLE.
///
/// ## Exemple d'utilisation
///
/// ```dart
/// import 'package:jni/jni.dart';
/// import 'package:my_package_ffi/ble.dart';
///
/// // 1. Obtenir le contexte Android et le BluetoothManager
/// //    (Le contexte doit être passé depuis le code Flutter/Android)
///
/// // 2. Obtenir l'adaptateur et le scanner
/// final adapter = bluetoothManager.getAdapter();
/// if (adapter == null || !adapter.isEnabled()) {
///   print('Bluetooth non disponible ou désactivé');
///   return;
/// }
///
/// final scanner = adapter.getBluetoothLeScanner();
/// if (scanner == null) {
///   print('Scanner BLE non disponible');
///   return;
/// }
///
/// // 3. Configurer les paramètres de scan
/// final settings = ScanSettings_Builder()
///     .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
///     .build();
///
/// // 4. Implémenter un callback (voir documentation jnigen pour les interfaces)
/// // Note: L'implémentation de ScanCallback en Dart nécessite Dart Callbacks
///
/// // 5. Démarrer le scan
/// scanner.startScan1(null, settings, callback);
///
/// // 6. Arrêter le scan
/// scanner.stopScan(callback);
/// ```
///
/// ## Classes disponibles
///
/// ### Gestion Bluetooth
/// - [BluetoothManager] - `getAdapter()` pour obtenir l'adaptateur
/// - [BluetoothAdapter] - `isEnabled()`, `getBluetoothLeScanner()`
/// - [BluetoothDevice] - `getAddress()`, `getName()`
///
/// ### Scanner BLE
/// - [BluetoothLeScanner] - `startScan()`, `stopScan()`
/// - [ScanResult] - `getDevice()`, `getRssi()`, `getScanRecord()`
/// - [ScanRecord] - `getBytes()`, `getDeviceName()`
/// - [ScanSettings] - Configuration (mode, délai, etc.)
/// - [ScanSettings_Builder] - Builder pour ScanSettings
/// - [ScanFilter] - Filtres par nom, adresse, service UUID
/// - [ScanFilter_Builder] - Builder pour ScanFilter
/// - [ScanCallback] - Classe abstraite pour les résultats
library;

export 'jni_bindings.dart';
