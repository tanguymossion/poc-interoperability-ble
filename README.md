# my_package_ffi - Scanner BLE via FFI/JNI

Un package Flutter pour le scan Bluetooth Low Energy (BLE) utilisant **directement les APIs natives** via JNI (Android) et FFI/Objective-C (iOS).

## ✨ Points forts

- **API unifiée cross-platform** - Même code pour Android et iOS
- **100% Dart** - Pas de code Java/Kotlin/Swift à écrire
- **Appels natifs directs** - Performance quasi-native
- **Callbacks en Dart** - Implémentation des callbacks en pur Dart

## 📱 Support des plateformes

| Plateforme | État | Technologie |
|------------|------|-------------|
| Android | ✅ Fonctionnel | JNI via jnigen |
| iOS | ✅ Fonctionnel | CoreBluetooth via ffigen |

## 🚀 API haut niveau (recommandée)

```dart
import 'package:my_package_ffi/ble.dart';

// Créer le scanner (détection automatique de la plateforme)
final scanner = createBleScanner();

// Initialiser
final success = await scanner.initialize();
if (!success) {
  print('Bluetooth non disponible');
  return;
}

// Écouter les appareils découverts
scanner.discoveredDevices.listen((device) {
  print('${device.name} (${device.identifier}) - ${device.rssi} dBm');
  print('  Distance estimée: ${device.estimatedDistance.toStringAsFixed(1)}m');
  print('  Signal: ${device.signalQuality}');
});

// Scanner pendant 10 secondes
await scanner.startScan(duration: Duration(seconds: 10));

// Libérer les ressources
scanner.dispose();
```

## 🔧 API bas niveau Android (accès direct JNI)

```dart
import 'package:my_package_ffi/ble.dart';

// Obtenir l'adaptateur (pas besoin de contexte !)
final adapter = BluetoothAdapter.getDefaultAdapter();

// Créer le callback en Dart pur !
final callback = BluetoothAdapter$LeScanCallback.implement(
  $BluetoothAdapter$LeScanCallback(
    onLeScan: (device, rssi, scanRecord) {
      final address = device?.getAddress()?.toDartString();
      final name = device?.getName()?.toDartString() ?? '';
      print('Trouvé: $name ($address) - $rssi dBm');
    },
  ),
);

// Scanner
adapter?.startLeScan(callback);
await Future.delayed(Duration(seconds: 10));
adapter?.stopLeScan(callback);

// Libérer
callback.release();
adapter?.release();
```

## 🍎 API bas niveau iOS (accès direct CoreBluetooth)

```dart
import 'package:my_package_ffi/ble.dart';

// Créer le delegate en Dart pur !
final delegate = CBCentralManagerDelegate$Builder.implement(
  centralManagerDidUpdateState_: (central) {
    print('État: ${central.state}');
    if (central.state == CBManagerState.CBManagerStatePoweredOn) {
      central.scanForPeripheralsWithServices(null);
    }
  },
  centralManager_didDiscoverPeripheral_advertisementData_RSSI_: 
    (central, peripheral, advertisementData, rssi) {
      print('Trouvé: ${peripheral.name} - ${rssi.intValue} dBm');
    },
);

// Créer le manager
final manager = CBCentralManager.alloc().initWithDelegate(delegate, queue: null);

// Arrêter le scan
manager.stopScan();
```

## 📦 Installation

### 1. Dépendances

```yaml
dependencies:
  my_package_ffi:
    path: ../  # ou depuis pub.dev
  jni: ^0.15.2
  objective_c: ^9.0.0
  permission_handler: ^11.3.1  # pour les permissions runtime
```

### 2. Permissions Android

Dans `android/app/src/main/AndroidManifest.xml` :

```xml
<!-- Android 11 et moins -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Pour le scan -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

### 3. Permissions iOS

Dans `ios/Runner/Info.plist` :

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Cette app utilise le Bluetooth pour scanner les appareils BLE</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Cette app utilise le Bluetooth pour scanner les appareils BLE</string>
```

### 4. Permissions runtime

```dart
import 'package:permission_handler/permission_handler.dart';

// Android
if (Platform.isAndroid) {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
}

// iOS - les permissions sont demandées automatiquement par CoreBluetooth
```

## 📚 Classes disponibles

### API haut niveau (cross-platform)

| Classe | Description |
|--------|-------------|
| `BleScanner` | Interface abstraite du scanner |
| `BleDevice` | Appareil BLE découvert |
| `BleScannerState` | État du scanner (ready, scanning, etc.) |
| `BleUtils` | Utilitaires (distance, qualité signal) |
| `createBleScanner()` | Factory cross-platform |

### API Android (bas niveau)

| Classe | Description |
|--------|-------------|
| `BluetoothAdapter` | Adaptateur local |
| `BluetoothDevice` | Appareil distant |
| `BluetoothAdapter$LeScanCallback` | Callback implémentable en Dart |

### API iOS (bas niveau)

| Classe | Description |
|--------|-------------|
| `CBCentralManager` | Gestionnaire central pour le scan |
| `CBCentralManagerDelegate$Builder` | Builder pour créer le delegate en Dart |
| `CBPeripheral` | Appareil BLE découvert |
| `CBManagerState` | État du Bluetooth |

## 🔧 Helpers Dart

```dart
// Estimer la distance depuis le RSSI
final distance = BleUtils.estimateDistance(-65); // → ~3.5 mètres

// Obtenir la qualité du signal
final quality = BleUtils.getSignalQuality(-65); // → "Bon"
```

## 🛠 Régénérer les bindings

### Android (jnigen)

```bash
dart run jnigen --config jnigen.yaml
```

### iOS (ffigen)

```bash
dart run ffigen --config ffigen_ios.yaml
```

## 📄 Licence

MIT License
