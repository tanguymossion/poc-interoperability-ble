import 'dart:math' as math;

/// Utilitaires pour le BLE.
class BleUtils {
  BleUtils._();

  /// Estime la distance en mètres basée sur le RSSI.
  ///
  /// [rssi] La puissance du signal en dBm.
  /// [txPower] La puissance de transmission de référence (défaut: -59 dBm).
  /// [pathLossExponent] L'exposant de perte de chemin (défaut: 2.0).
  static double estimateDistance(
    int rssi, {
    int txPower = -59,
    double pathLossExponent = 2.0,
  }) {
    return math
        .pow(10.0, (txPower - rssi) / (10 * pathLossExponent))
        .toDouble();
  }

  /// Retourne une description de la qualité du signal.
  static String getSignalQuality(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Très bon';
    if (rssi >= -70) return 'Bon';
    if (rssi >= -80) return 'Moyen';
    return 'Faible';
  }
}

/// Erreur de scan BLE.
class BleScanException implements Exception {
  final String message;
  final int? errorCode;

  const BleScanException(this.message, [this.errorCode]);

  @override
  String toString() =>
      'BleScanException: $message${errorCode != null ? ' (code: $errorCode)' : ''}';
}

/// État du scanner BLE.
enum BleScannerState { ready, scanning, unavailable, disabled, unauthorized }
