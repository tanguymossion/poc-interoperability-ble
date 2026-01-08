/// Package BLE utilisant JNI pour accéder aux APIs Android natives.
///
/// Ce package expose directement les classes Android BLE via jnigen,
/// permettant un scan BLE 100% Dart sans code natif supplémentaire.
///
/// ## Exemple de scan BLE fonctionnel
///
/// ```dart
/// import 'package:my_package_ffi/ble.dart';
///
/// // 1. Obtenir l'adaptateur (pas besoin de contexte !)
/// final adapter = BluetoothAdapter.getDefaultAdapter();
///
/// // 2. Créer le callback en Dart
/// final callback = BluetoothAdapter$LeScanCallback.implement(
///   $BluetoothAdapter$LeScanCallback(
///     onLeScan: (device, rssi, scanRecord) {
///       print('Trouvé: ${device?.getName()} - $rssi dBm');
///     },
///   ),
/// );
///
/// // 3. Démarrer/arrêter le scan
/// adapter?.startLeScan(callback);
/// // ... après quelques secondes ...
/// adapter?.stopLeScan(callback);
/// ```
library;

// Classes Android BLE natives (générées par jnigen)
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
        // Callback pour le scan (ancienne API, mais implémentable en Dart !)
        // ignore: camel_case_types
        BluetoothAdapter$LeScanCallback,
        // ignore: camel_case_types
        $BluetoothAdapter$LeScanCallback;

// Helpers Dart
export 'src/ble_scanner.dart' show BleUtils, BleScanException, BleScannerState;
