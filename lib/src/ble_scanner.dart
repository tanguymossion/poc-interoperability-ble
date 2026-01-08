import 'dart:async';
import 'dart:math' as math;

/// Représente un appareil BLE découvert.
class BleDevice {
  /// Identifiant unique (adresse MAC sur Android, UUID sur iOS).
  final String identifier;

  /// Nom de l'appareil (peut être vide).
  final String name;

  /// Puissance du signal en dBm.
  final int rssi;

  /// Données d'advertisement brutes (optionnel).
  final List<int>? advertisementData;

  /// Horodatage de la découverte.
  final DateTime discoveredAt;

  BleDevice({
    required this.identifier,
    required this.name,
    required this.rssi,
    this.advertisementData,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  bool get hasName => name.isNotEmpty;

  /// Estimation de la distance en mètres basée sur le RSSI.
  double get estimatedDistance => BleUtils.estimateDistance(rssi);

  /// Qualité du signal.
  String get signalQuality => BleUtils.getSignalQuality(rssi);

  @override
  String toString() => 'BleDevice($identifier, $name, $rssi dBm)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDevice && identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}

/// État du scanner BLE.
enum BleScannerState {
  /// Scanner non initialisé.
  uninitialized,

  /// Prêt à scanner.
  ready,

  /// Scan en cours.
  scanning,

  /// Bluetooth non disponible sur l'appareil.
  unavailable,

  /// Bluetooth désactivé.
  disabled,

  /// Permissions non accordées.
  unauthorized,
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

/// Interface abstraite pour le scanner BLE.
///
/// Implémentée par [BleScannerAndroid] et [BleScannerIOS].
abstract class BleScanner {
  /// État actuel du scanner.
  BleScannerState get state;

  /// Stream des appareils découverts pendant le scan.
  Stream<BleDevice> get discoveredDevices;

  /// Initialise le scanner.
  ///
  /// Doit être appelé avant toute autre opération.
  /// Retourne `true` si l'initialisation a réussi.
  Future<bool> initialize();

  /// Vérifie si le Bluetooth est disponible sur l'appareil.
  Future<bool> isBluetoothAvailable();

  /// Vérifie si le Bluetooth est activé.
  Future<bool> isBluetoothEnabled();

  /// Démarre le scan BLE.
  ///
  /// [duration] : Durée du scan (null = infini jusqu'à [stopScan]).
  /// Retourne `true` si le scan a démarré avec succès.
  Future<bool> startScan({Duration? duration});

  /// Arrête le scan en cours.
  Future<void> stopScan();

  /// Libère les ressources.
  void dispose();

  /// Crée le scanner approprié pour la plateforme courante.
  ///
  /// Retourne [BleScannerAndroid] sur Android, [BleScannerIOS] sur iOS.
  /// Throws [UnsupportedError] sur les autres plateformes.
  static BleScanner create() {
    // Import conditionnel géré dans les fichiers platform-specific
    throw UnsupportedError(
      'BleScanner.create() doit être appelé depuis ble_scanner_factory.dart',
    );
  }
}

/// Utilitaires pour le BLE.
class BleUtils {
  BleUtils._();

  /// Estime la distance en mètres basée sur le RSSI.
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
