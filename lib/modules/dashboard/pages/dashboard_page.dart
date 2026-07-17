import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/services/serial_port_service.dart';
import '../../../../core/services/gateway_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
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

  TelemetryData? _currentData;
  final List<ConsoleLog> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = Provider.of<GatewayStateProvider>(context, listen: false);
      if (s.isSerialConnected) _startSerial(s);
    });
  }

  void _startSerial(GatewayStateProvider s) {
    _stopSerial();
    _telemetrySub = _serialService.telemetryStream.listen((d) {
      if (mounted) setState(() => _currentData = d);
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
    final ok = _serialService.connect(s.activePort, s.baudRate);
    if (!ok) {
      s.setSerialConnected(false);
      setState(() {
        _consoleLogs.add(ConsoleLog(
          timestamp: DateTime.now(), nodeId: 'SYSTEM',
          rawBytes: Uint8List.fromList(utf8.encode('ERROR: Port ${s.activePort} not available')),
          isValid: false, details: 'PORT NOT FOUND',
        ));
      });
    }
  }

  void _stopSerial() {
    _telemetrySub?.cancel(); _telemetrySub = null;
    _consoleSub?.cancel(); _consoleSub = null;
    _serialService.disconnect();
  }

  @override
  void dispose() { _stopSerial(); _serialService.dispose(); super.dispose(); }

  void _toggleSerial(GatewayStateProvider s) {
    if (s.isSerialConnected) {
      _stopSerial(); s.setSerialConnected(false);
      setState(() => _currentData = null);
    } else {
      s.setSerialConnected(true); _startSerial(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<GatewayStateProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            StatusBar(
              isSerialConnected: s.isSerialConnected,
              isMqttConnected: s.isMqttConnected,
              isInternetConnected: s.isInternetConnected,
              activePort: s.activePort,
              activeNode: s.activeNodeId,
            ),

            // ── Body ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Telemetry (flex-expanded)
                    Expanded(
                      child: TelemetryPanel(data: _currentData),
                    ),

                    const SizedBox(width: 12),

                    // Right Column: Camera + Console (width constrained)
                    SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // CCTV aspect ratio 16:9
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPanel(rtspUrl: s.rtspUrl, cameraName: 'CCTV-TAMBAK-01'),
                          ),
                          const SizedBox(height: 10),
                          // Serial Console
                          Expanded(
                            child: ConsolePanel(
                              logs: _consoleLogs,
                              onClear: () => setState(() => _consoleLogs.clear()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppTheme.card,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: AppTheme.t3),
                  const SizedBox(width: 4),
                  Text(
                    _currentData != null
                        ? 'Last update: ${_fmt(_currentData!.timestamp)}'
                        : 'Waiting for data…',
                    style: const TextStyle(color: AppTheme.t3, fontSize: 10),
                  ),
                  const Spacer(),
                  _actionBtn(Icons.usb, 'Serial', s.isSerialConnected, () => _toggleSerial(s)),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.cloud_sync, 'MQTT', s.isMqttConnected, s.toggleMqtt),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.language, 'API', s.isInternetConnected, s.toggleInternet),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 20, color: AppTheme.border),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showSettings(s),
                    icon: const Icon(Icons.settings_outlined, size: 16, color: AppTheme.t2),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? AppTheme.accent : AppTheme.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: on ? AppTheme.accent : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: on ? Colors.white : AppTheme.t3),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: on ? Colors.white : AppTheme.t3, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Settings Dialog ──
  void _showSettings(GatewayStateProvider s) {
    String port = s.activePort;
    int baud = s.baudRate;
    final node = TextEditingController(text: s.activeNodeId);
    final rtsp = TextEditingController(text: s.rtspUrl);
    final mHost = TextEditingController(text: s.mqttHost);
    final mPort = TextEditingController(text: s.mqttPort.toString());
    final mUser = TextEditingController(text: s.mqttUsername);
    final mPass = TextEditingController(text: s.mqttPassword);

    showDialog(
      context: context,
      builder: (ctx) {
        final ports = List<String>.from(SerialPortService.getAvailablePorts());
        if (!ports.contains(port)) ports.add(port);
        final bauds = [4800, 9600, 19200, 38400, 57600, 115200];
        if (!bauds.contains(baud)) { bauds.add(baud); bauds.sort(); }

        return StatefulBuilder(builder: (ctx, dss) {
          return AlertDialog(
            title: Row(children: [
              const Icon(Icons.tune, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              const Text('Gateway Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.t1)),
            ]),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectLabel('Serial Port'),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: _dd<String>('Port', port, ports.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(), (v) { if (v != null) dss(() => port = v); })),
                      const SizedBox(width: 8),
                      Expanded(child: _dd<int>('Baud', baud, bauds.map((b) => DropdownMenuItem(value: b, child: Text('$b', style: const TextStyle(fontSize: 12)))).toList(), (v) { if (v != null) dss(() => baud = v); })),
                    ]),
                    const SizedBox(height: 16),
                    _sectLabel('MQTT Broker'),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(flex: 3, child: _tf('Host', mHost)),
                      const SizedBox(width: 8),
                      Expanded(child: _tf('Port', mPort)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: _tf('User', mUser)),
                      const SizedBox(width: 8),
                      Expanded(child: _tf('Password', mPass, obscure: true)),
                    ]),
                    const SizedBox(height: 16),
                    _sectLabel('Node & CCTV'),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: _tf('Node ID', node)),
                      const SizedBox(width: 8),
                      Expanded(child: _tf('RTSP URL', rtsp)),
                    ]),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.t3))),
              ElevatedButton(
                onPressed: () {
                  s.updateSettings(
                    activePort: port, baudRate: baud,
                    activeNodeId: node.text, rtspUrl: rtsp.text,
                    mqttHost: mHost.text, mqttPort: int.tryParse(mPort.text) ?? 1883,
                    mqttUsername: mUser.text, mqttPassword: mPass.text,
                  );
                  if (s.isSerialConnected) _startSerial(s);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _sectLabel(String t) => Text(t, style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700));

  Widget _dd<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.t3, fontSize: 9, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        DropdownButtonFormField<T>(
          initialValue: value, items: items, onChanged: onChanged,
          dropdownColor: AppTheme.card,
          style: const TextStyle(color: AppTheme.t1, fontSize: 12),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accent), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _tf(String label, TextEditingController c, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.t3, fontSize: 9, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        TextField(
          controller: c, obscureText: obscure,
          style: const TextStyle(color: AppTheme.t1, fontSize: 12),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accent), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
}
