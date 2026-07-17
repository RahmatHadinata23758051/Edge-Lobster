import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/services/serial_port_service.dart';
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
  final SerialPortService _serialService = SerialPortService();
  StreamSubscription<TelemetryData>? _telemetrySub;
  StreamSubscription<ConsoleLog>? _consoleSub;

  // App States
  TelemetryData? _currentData;
  final List<ConsoleLog> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<GatewayStateProvider>(context, listen: false);
      if (state.isSerialConnected) {
        _startSerialConnection(state);
      }
    });
  }

  void _startSerialConnection(GatewayStateProvider state) {
    _stopSerialConnection();

    _telemetrySub = _serialService.telemetryStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
        });
      }
    });

    _consoleSub = _serialService.rawConsoleStream.listen((log) {
      if (mounted) {
        setState(() {
          _consoleLogs.add(log);
          if (_consoleLogs.length > 100) {
            _consoleLogs.removeAt(0);
          }
        });
      }
    });

    final success = _serialService.connect(state.activePort, state.baudRate);
    if (!success) {
      state.setSerialConnected(false);

      final failLog = ConsoleLog(
        timestamp: DateTime.now(),
        nodeId: 'SYSTEM',
        rawBytes: Uint8List.fromList(utf8.encode('ERROR: Gagal membuka port ${state.activePort}')),
        isValid: false,
        details: 'PORT NOT FOUND OR BUSY | CHECK PHYSICAL CONNECTION',
      );
      setState(() {
        _consoleLogs.add(failLog);
      });
    }
  }

  void _stopSerialConnection() {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _consoleSub?.cancel();
    _consoleSub = null;
    _serialService.disconnect();
  }

  @override
  void dispose() {
    _stopSerialConnection();
    _serialService.dispose();
    super.dispose();
  }

  void _handleToggleSerial(GatewayStateProvider state) {
    if (state.isSerialConnected) {
      _stopSerialConnection();
      state.setSerialConnected(false);
      setState(() {
        _currentData = null;
      });
    } else {
      state.setSerialConnected(true);
      _startSerialConnection(state);
    }
  }

  void _showSettingsDialog(GatewayStateProvider state) {
    final portController = TextEditingController(text: state.activePort);
    final baudController = TextEditingController(text: state.baudRate.toString());
    final nodeController = TextEditingController(text: state.activeNodeId);
    final rtspController = TextEditingController(text: state.rtspUrl);
    final mqttHostController = TextEditingController(text: state.mqttHost);
    final mqttPortController = TextEditingController(text: state.mqttPort.toString());
    final mqttUserController = TextEditingController(text: state.mqttUsername);
    final mqttPassController = TextEditingController(text: state.mqttPassword);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: const BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFF334155), width: 1.0),
          ),
          title: Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF334155), width: 1.0),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, color: Colors.blueAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'EDGE GATEWAY SYSTEM SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SERIAL CONFIG SECTION ---
                  const Text(
                    '// SERIAL PORT RECEIVER CONFIGURATION',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(label: 'PORT (e.g. COM3 / ttyUSB0)', controller: portController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(label: 'BAUD RATE', controller: baudController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- MQTT BROKER SECTION ---
                  const Text(
                    '// MQTT BROKER CONFIGURATION (CLOUD TRANSMISSION)',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(label: 'BROKER HOST', controller: mqttHostController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildTextField(label: 'PORT', controller: mqttPortController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(label: 'USERNAME', controller: mqttUserController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(label: 'PASSWORD', controller: mqttPassController, isObscure: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- CCTV & NODE CONFIG SECTION ---
                  const Text(
                    '// NODE MONITORING & LIVE CCTV FEED CONFIGURATION',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(label: 'MONITORED NODE ID', controller: nodeController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(label: 'LOCAL CCTV RTSP URL', controller: rtspController),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF334155)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('CANCEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final baudValue = int.tryParse(baudController.text) ?? 9600;
                final mqttPortValue = int.tryParse(mqttPortController.text) ?? 1883;

                state.updateSettings(
                  activePort: portController.text,
                  baudRate: baudValue,
                  activeNodeId: nodeController.text,
                  rtspUrl: rtspController.text,
                  mqttHost: mqttHostController.text,
                  mqttPort: mqttPortValue,
                  mqttUsername: mqttUserController.text,
                  mqttPassword: mqttPassController.text,
                );

                if (state.isSerialConnected) {
                  _startSerialConnection(state);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('SAVE & APPLY CONFIG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
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
            StatusBar(
              isSerialConnected: state.isSerialConnected,
              isMqttConnected: state.isMqttConnected,
              isInternetConnected: state.isInternetConnected,
              activePort: state.activePort,
              activeNode: state.activeNodeId,
            ),

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

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: TelemetryPanel(data: _currentData),
                  ),

                  Container(
                    width: 1,
                    color: const Color(0xFF334155),
                  ),

                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 6,
                          child: VideoPanel(
                            rtspUrl: state.rtspUrl,
                            cameraName: 'CCTV-TAMBAK-01',
                          ),
                        ),

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
