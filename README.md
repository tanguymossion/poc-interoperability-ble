# my_package_ffi

> 🧪 **POC** — Proof of Concept d'interopérabilité Flutter native

## Concept

Accéder aux **APIs Bluetooth natives** (Android & iOS) **directement depuis Dart**, sans écrire de code Java/Kotlin/Swift et sans Method Channels.

| Plateforme | Technologie |
|------------|-------------|
| Android | JNI via [jnigen](https://pub.dev/packages/jnigen) |
| iOS | FFI/Objective-C via [ffigen](https://pub.dev/packages/ffigen) |

## Exemple

```dart
import 'package:my_package_ffi/ble.dart';

final scanner = createBleScanner();
await scanner.initialize();

scanner.discoveredDevices.listen((device) {
  print('${device.name} - ${device.rssi} dBm');
});

await scanner.startScan(duration: Duration(seconds: 10));
scanner.dispose();
```

## Structure

```
lib/
├── ble.dart                      # Export public
└── src/
    ├── ble_scanner.dart          # Interface abstraite
    ├── ble_scanner_factory.dart  # Factory cross-platform
    ├── android/
    │   ├── jni_bindings.dart     # Bindings générés (jnigen)
    │   └── ble_scanner_android.dart
    └── ios/
        ├── corebluetooth_bindings.dart   # Bindings générés (ffigen)
        ├── corebluetooth_bindings.dart.m # Trampolines ObjC
        └── ble_scanner_ios.dart
```

## Régénérer les bindings

```bash
# Android
dart run jnigen --config jnigen.yaml

# iOS
dart run ffigen --config ffigen_ios.yaml
```
