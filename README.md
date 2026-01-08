# my_package_ffi - Scanner BLE via JNI

Un package Flutter pour le scan Bluetooth Low Energy (BLE) sur Android, utilisant **directement les APIs Android natives** via JNI et jnigen.

## ✨ Points forts

- **100% Dart** - Pas de code Java/Kotlin à écrire
- **Appels JNI directs** - Performance quasi-native
- **APIs Android natives** - Utilise directement `BluetoothAdapter`, `BluetoothDevice`, etc.
- **Callback en Dart** - Implémentation du callback de scan en pur Dart

## 🚀 Exemple de scan fonctionnel

```dart
import 'package:my_package_ffi/ble.dart';

// 1. Obtenir l'adaptateur (pas besoin de contexte !)
final adapter = BluetoothAdapter.getDefaultAdapter();

// 2. Vérifier que le Bluetooth est activé
if (adapter == null || !adapter.isEnabled()) {
  print('Bluetooth non disponible ou désactivé');
  return;
}

// 3. Créer le callback en Dart pur !
final callback = BluetoothAdapter$LeScanCallback.implement(
  $BluetoothAdapter$LeScanCallback(
    onLeScan: (device, rssi, scanRecord) {
      final address = device?.getAddress()?.toDartString();
      final name = device?.getName()?.toDartString() ?? '';
      print('Trouvé: $name ($address) - $rssi dBm');
    },
  ),
);

// 4. Démarrer le scan
adapter.startLeScan(callback);

// 5. Arrêter après 10 secondes
await Future.delayed(Duration(seconds: 10));
adapter.stopLeScan(callback);

// 6. Libérer les ressources
callback.release();
adapter.release();
```

## 📱 Installation

### 1. Dépendances

```yaml
dependencies:
  my_package_ffi:
    path: ../  # ou depuis pub.dev
  jni: ^0.15.2
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

### 3. Demander les permissions runtime

Sur Android 12+, demandez les permissions avant de scanner :

```dart
// Utiliser permission_handler ou similar
await Permission.bluetoothScan.request();
await Permission.bluetoothConnect.request();
await Permission.location.request();
```

## 📚 Classes disponibles

| Classe | Description |
|--------|-------------|
| `BluetoothAdapter` | Adaptateur local, `getDefaultAdapter()`, `startLeScan()` |
| `BluetoothDevice` | Appareil distant, `getAddress()`, `getName()` |
| `BluetoothAdapter$LeScanCallback` | Callback implémentable en Dart ! |
| `BluetoothManager` | Point d'entrée (nécessite contexte) |
| `BluetoothLeScanner` | Scanner nouvelle API (callback non implémentable) |
| `ScanResult` | Résultat de scan (nouvelle API) |

## 🔧 Helpers Dart

```dart
// Estimer la distance depuis le RSSI
BleUtils.estimateDistance(-65); // → ~3.5 mètres

// Obtenir la qualité du signal
BleUtils.getSignalQuality(-65); // → "Bon"
```

## 🛠 Régénérer les bindings

```bash
dart run jnigen --config jnigen.yaml
```

## ⚠️ Limitations

- **Android uniquement** - iOS nécessiterait CoreBluetooth via ffigen
- **API LeScan** - Utilise l'ancienne API (deprecated mais fonctionnelle) car c'est la seule avec callback implémentable en Dart
- **Permissions** - Nécessite les permissions Bluetooth et Localisation

## 📄 Licence

MIT License
