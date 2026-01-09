import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_package_ffi/ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BleScannerPage(),
    );
  }
}

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  // Scanner cross-platform (Android + iOS)
  BleScanner? _scanner;
  StreamSubscription<BleDevice>? _scanSubscription;

  final Map<String, BleDevice> _devicesMap = {};
  List<BleDevice> get _devices {
    final list = _devicesMap.values.toList();
    list.sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  bool _isScanning = false;
  String _statusMessage = 'Initialisation...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    // Demander les permissions (Android uniquement)
    if (Platform.isAndroid) {
      setState(() => _statusMessage = 'Demande des permissions...');

      final permissions = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final allGranted = permissions.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (!allGranted) {
        setState(() {
          _errorMessage = 'Permissions Bluetooth/Localisation requises';
          _statusMessage = 'Permissions refusées';
        });
        return;
      }
    }

    setState(() => _statusMessage = 'Initialisation du Bluetooth...');

    try {
      // Créer le scanner (détecte automatiquement la plateforme)
      _scanner = createBleScanner();

      // Initialiser
      await _scanner!.initialize();

      // Écouter les appareils découverts
      _scanSubscription = _scanner!.discoveredDevices.listen((device) {
        if (mounted) {
          setState(() {
            _devicesMap[device.identifier] = device;
          });
        }
      });

      setState(() {
        _statusMessage = 'Prêt à scanner';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _statusMessage = 'Erreur d\'initialisation';
      });
    }
  }

  Future<void> _startScan() async {
    if (_scanner == null) {
      await _initScanner();
      if (_scanner == null) return;
    }

    setState(() {
      _isScanning = true;
      _devicesMap.clear();
      _statusMessage = 'Scan en cours...';
      _errorMessage = null;
    });

    try {
      await _scanner!.startScan(duration: const Duration(seconds: 15));
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de scan: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = '${_devicesMap.length} appareil(s) trouvé(s)';
      });
    }
  }

  Future<void> _stopScan() async {
    await _scanner?.stopScan();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = '${_devicesMap.length} appareil(s) trouvé(s)';
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanner?.dispose();
    super.dispose();
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return const Color(0xFF00E676);
    if (rssi >= -70) return const Color(0xFFFFEB3B);
    return const Color(0xFFFF5722);
  }

  IconData _getRssiIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_cellular_4_bar;
    if (rssi >= -70) return Icons.signal_cellular_alt;
    return Icons.signal_cellular_alt_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        elevation: 0,
        leading: const Icon(Icons.bluetooth, color: Color(0xFF00B4D8)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isScanning
                  ? const Color(0xFF00B4D8).withOpacity(0.2)
                  : const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isScanning
                    ? const Color(0xFF00B4D8)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isScanning)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00B4D8),
                    ),
                  )
                else
                  Icon(
                    _errorMessage != null
                        ? Icons.error_outline
                        : Icons.info_outline,
                    size: 14,
                    color: _errorMessage != null
                        ? const Color(0xFFFF5722)
                        : const Color(0xFF90CAF9),
                  ),
                const SizedBox(width: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isScanning
                        ? const Color(0xFF00B4D8)
                        : _errorMessage != null
                        ? const Color(0xFFFF5722)
                        : const Color(0xFF90CAF9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00B4D8).withOpacity(0.15),
                  const Color(0xFF0077B6).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00B4D8).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _errorMessage != null
                      ? Icons.warning_amber
                      : Icons.bluetooth_searching,
                  color: _errorMessage != null
                      ? const Color(0xFFFFEB3B)
                      : const Color(0xFF00B4D8),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage != null
                            ? 'Attention'
                            : 'Scan BLE Cross-Platform',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage ??
                            (Platform.isIOS
                                ? 'APIs CoreBluetooth natives via FFI'
                                : 'APIs Android natives via JNI'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _errorMessage != null
                              ? const Color(0xFFFFEB3B)
                              : const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isScanning
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth_disabled,
                          size: 64,
                          color: const Color(0xFF1E3A5F),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Recherche en cours...'
                              : 'Aucun appareil',
                          style: const TextStyle(
                            color: Color(0xFF5C7A99),
                            fontSize: 16,
                          ),
                        ),
                        if (!_isScanning && _errorMessage == null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Appuyez sur le bouton pour scanner',
                            style: TextStyle(
                              color: Color(0xFF3D5A73),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return _buildDeviceCard(device);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        backgroundColor: _isScanning
            ? const Color(0xFFE53935)
            : const Color(0xFF00B4D8),
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? 'Arrêter' : 'Scanner'),
      ),
    );
  }

  Widget _buildDeviceCard(BleDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sélectionné: ${device.identifier}'),
                backgroundColor: const Color(0xFF00B4D8),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bluetooth icon with signal indicator
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getRssiColor(device.rssi).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: _getRssiColor(device.rssi),
                        size: 28,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          _getRssiIcon(device.rssi),
                          color: _getRssiColor(device.rssi),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Device info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.hasName ? device.name : 'Appareil inconnu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: device.hasName
                              ? Colors.white
                              : const Color(0xFF5C7A99),
                          fontStyle: device.hasName
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.identifier,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5C7A99),
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~${device.estimatedDistance.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF5C7A99).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // RSSI value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRssiColor(device.rssi).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${device.rssi} dBm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _getRssiColor(device.rssi),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.signalQuality,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRssiColor(device.rssi).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF3D5A73)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
