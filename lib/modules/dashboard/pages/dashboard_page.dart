import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/services/mock_telemetry_service.dart';
import '../../../../core/services/gateway_state_provider.dart';
import '../components/status_bar.dart';
import '../components/telemetry_panel.dart';
import '../components/video_panel.dart';
import '../components/console_panel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MockTelemetryService _telemetryService = MockTelemetryService();
  StreamSubscription<TelemetryData>? _subscription;

  // App States
  TelemetryData? _currentData;
  final List<ConsoleLog> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    // Gunakan post frame callback untuk memulai generator telemetry
    // karena membutuhkan parameter dari provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<GatewayStateProvider>(context, listen: false);
      if (state.isSerialConnected) {
        _startTelemetry(state.activeNodeId);
      }
    });
  }

  void _startTelemetry(String nodeId) {
    _telemetryService.startGenerating(nodeId);
    _subscription = _telemetryService.telemetryStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
          _addConsoleLogFor(data);
        });
      }
    });
  }

  void _stopTelemetry() {
    _subscription?.cancel();
    _telemetryService.stopGenerating();
  }

  void _addConsoleLogFor(TelemetryData data) {
    // Buat biner payload 55-byte palsu berdasarkan data telemetri
    final bytes = Uint8List(55);
    final byteData = ByteData.sublistView(bytes);

    // Tulis nilai float (mirip dengan LoraParser)
    byteData.setFloat32(0, data.temperature, Endian.little);
    byteData.setFloat32(4, data.ph, Endian.little);
    byteData.setFloat32(8, data.salinity, Endian.little);
    byteData.setFloat32(12, data.dissolvedOxygen, Endian.little);
    byteData.setFloat32(16, data.turbidity, Endian.little);
    byteData.setFloat32(20, data.flowSpeed, Endian.little);
    byteData.setFloat32(24, data.solarVoltage, Endian.little);
    byteData.setFloat32(28, data.solarCurrent, Endian.little);
    byteData.setFloat32(32, data.batteryVoltage, Endian.little);
    byteData.setFloat32(36, data.latitude, Endian.little);
    byteData.setFloat32(40, data.longitude, Endian.little);

    // Sisa byte 44-54 diisi byte padding/checksum
    final random = Random();
    for (int i = 44; i < 55; i++) {
      bytes[i] = random.nextInt(256);
    }

    final newLog = ConsoleLog(
      timestamp: DateTime.now(),
      nodeId: data.serialNumber,
      rawBytes: bytes,
      isValid: true,
      details: 'PARSED OK | RSSI: -84dBm | SNR: 8.5dB',
    );

    setState(() {
      _consoleLogs.add(newLog);
      if (_consoleLogs.length > 100) {
        _consoleLogs.removeAt(0); // Batasi log maks 100
      }
    });
  }

  @override
  void dispose() {
    _stopTelemetry();
    _telemetryService.dispose();
    super.dispose();
  }

  // Interactive triggers untuk testing koneksi
  void _handleToggleSerial(GatewayStateProvider state) {
    state.toggleSerial();
    if (!state.isSerialConnected) {
      _stopTelemetry();
      setState(() {
        _currentData = null;
      });
    } else {
      _startTelemetry(state.activeNodeId);
    }
  }

  void _showSettingsDialog(GatewayStateProvider state) {
    final portController = TextEditingController(text: state.activePort);
    final nodeController = TextEditingController(text: state.activeNodeId);
    final rtspController = TextEditingController(text: state.rtspUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: const BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFF334155), width: 1.0),
          ),
          title: const Text(
            'EDGE SYSTEM CONFIGURATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(label: 'RECEIVER SERIAL PORT', controller: portController),
              const SizedBox(height: 12),
              _buildTextField(label: 'MONITORED NODE ID', controller: nodeController),
              const SizedBox(height: 12),
              _buildTextField(label: 'LOCAL CCTV RTSP URL', controller: rtspController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () {
                state.updateSettings(
                  activePort: portController.text,
                  activeNodeId: nodeController.text,
                  rtspUrl: rtspController.text,
                );
                
                // Restart telemetry dengan node ID baru jika serial terkoneksi
                if (state.isSerialConnected) {
                  _stopTelemetry();
                  _startTelemetry(nodeController.text);
                }
                Navigator.pop(context);
              },
              child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFF0F172A),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF334155), width: 1.0),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GatewayStateProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Status Connection Bar (Membaca state real-time dari provider)
            StatusBar(
              isSerialConnected: state.isSerialConnected,
              isMqttConnected: state.isMqttConnected,
              isInternetConnected: state.isInternetConnected,
              activePort: state.activePort,
              activeNode: state.activeNodeId,
            ),

            // Top Action Menu Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CONTROL PANEL GATEWAY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Simulators buttons
                      _buildHeaderButton(
                        label: 'TOGGLE SERIAL',
                        onPressed: () => _handleToggleSerial(state),
                        color: state.isSerialConnected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        label: 'TOGGLE MQTT',
                        onPressed: state.toggleMqtt,
                        color: state.isMqttConnected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        label: 'TOGGLE API SYNC',
                        onPressed: state.toggleInternet,
                        color: state.isInternetConnected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 16, color: const Color(0xFF334155)),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => _showSettingsDialog(state),
                        icon: const Icon(Icons.settings, color: Colors.white, size: 16),
                        tooltip: 'Configure Gateway Settings',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dashboard Panels Grid Layout (60-40 Split)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left panel: Telemetry Values (60% width)
                  Expanded(
                    flex: 6,
                    child: TelemetryPanel(data: _currentData),
                  ),

                  // Vertical divider
                  Container(
                    width: 1,
                    color: const Color(0xFF334155),
                  ),

                  // Right panel: CCTV and Console logs (40% width)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Right-Top: CCTV Feed (60% height of column)
                        Expanded(
                          flex: 6,
                          child: VideoPanel(
                            rtspUrl: state.rtspUrl,
                            cameraName: 'CCTV-TAMBAK-01',
                          ),
                        ),

                        // Right-Bottom: RAW Binary Hex Log (40% height of column)
                        Expanded(
                          flex: 4,
                          child: ConsolePanel(
                            logs: _consoleLogs,
                            onClear: () {
                              setState(() {
                                _consoleLogs.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
