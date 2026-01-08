import 'dart:io';

import 'ble_scanner.dart';
import 'android/ble_scanner_android.dart';
import 'ios/ble_scanner_ios.dart';

/// Crée le scanner BLE approprié pour la plateforme courante.
///
/// Retourne [BleScannerAndroid] sur Android, [BleScannerIOS] sur iOS.
/// Throws [UnsupportedError] sur les autres plateformes.
///
/// Exemple :
/// ```dart
/// final scanner = createBleScanner();
/// await scanner.initialize();
/// await scanner.startScan(duration: Duration(seconds: 10));
/// scanner.discoveredDevices.listen((device) {
///   print('Trouvé: ${device.name} - ${device.rssi} dBm');
/// });
/// ```
BleScanner createBleScanner() {
  if (Platform.isAndroid) {
    return BleScannerAndroid();
  } else if (Platform.isIOS) {
    return BleScannerIOS();
  } else {
    throw UnsupportedError(
      'BLE scanning is only supported on Android and iOS. '
      'Current platform: ${Platform.operatingSystem}',
    );
  }
}
