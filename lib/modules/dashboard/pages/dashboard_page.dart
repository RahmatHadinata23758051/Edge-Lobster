import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/services/serial_port_service.dart';
import '../../../../core/services/mock_telemetry_service.dart';
import '../../../../core/services/mqtt_publisher_service.dart';
import '../../../../core/services/gateway_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../components/telemetry_panel.dart';
import '../components/video_panel.dart';
import '../components/console_panel.dart';
import '../components/settings_panel.dart';

import '../../../../core/services/offline_buffer_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SerialPortService _serialService = SerialPortService();
  final MockTelemetryService _mockService = MockTelemetryService();
  final MqttPublisherService _mqttService = MqttPublisherService();
  final OfflineBufferService _bufferService = OfflineBufferService();

  StreamSubscription<TelemetryData>? _telemetrySub;
  StreamSubscription<TelemetryData>? _mockTelemetrySub;
  StreamSubscription<ConsoleLog>? _consoleSub;
  StreamSubscription<bool>? _mqttStateSub;
  StreamSubscription<String>? _mqttLogSub;

  TelemetryData? _currentData;
  final List<ConsoleLog> _consoleLogs = [];

  // Sidebar Menu State
  int _selectedIndex = 0; // 0 = Dashboard, 1 = Settings

  // Local Clock State
  late DateTime _currentTime;
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _bufferService.init();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Listen for MQTT logs to show in terminal console panel
    _mqttLogSub = _mqttService.logStream.listen((logMsg) {
      if (mounted) {
        setState(() {
          _consoleLogs.add(ConsoleLog(
            timestamp: DateTime.now(),
            nodeId: 'MQTT',
            rawBytes: Uint8List.fromList(utf8.encode(logMsg)),
            isValid: true,
            details: logMsg,
          ));
          if (_consoleLogs.length > 100) {
            _consoleLogs.removeAt(0);
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = Provider.of<GatewayStateProvider>(context, listen: false);

      // Listen for MQTT connection state changes to update Provider state
      _mqttStateSub = _mqttService.connectionStateStream.listen((isConn) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && s.isMqttConnected != isConn) {
              s.setMqttConnected(isConn);
            }
          });
        }
        if (isConn) {
          _bufferService.flushBuffer(_mqttService);
        }
      });

      // Start serial stream or fallback mock
      if (s.isSerialConnected) {
        _startSerial(s);
      } else {
        _startMock(s);
      }

      // Start MQTT client if enabled
      if (s.isMqttConnected) {
        _startMqtt(s);
      }
    });
  }

  void _onTelemetryReceived(TelemetryData d, GatewayStateProvider s) async {
    if (mounted) {
      setState(() => _currentData = d);

      if (s.isMqttConnected && _mqttService.isConnected) {
        final ok = await _mqttService.publishTelemetry(d);
        if (!ok) {
          await _bufferService.insertTelemetry(d);
        }
      } else {
        await _bufferService.insertTelemetry(d);
      }
    }
  }

  void _startSerial(GatewayStateProvider s) {
    _stopSerial();
    _stopMock();

    _telemetrySub = _serialService.telemetryStream.listen((d) {
      _onTelemetryReceived(d, s);
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
    if (ok) {
      s.setSerialConnected(true);
      _stopMock();
    } else {
      s.setSerialConnected(false);
      setState(() {
        _consoleLogs.add(ConsoleLog(
          timestamp: DateTime.now(),
          nodeId: 'SYSTEM',
          rawBytes: Uint8List.fromList(utf8.encode('{"ts":"${DateTime.now().toIso8601String()}", "node":"AQ-01", "status":"SERIAL PORT NOT FOUND - FALLBACK TO MOCK"}')),
          isValid: false,
          details: 'PORT NOT FOUND',
        ));
      });
      _startMock(s);
    }
  }

  void _startMock(GatewayStateProvider s) {
    _stopMock();
    _mockTelemetrySub = _mockService.telemetryStream.listen((d) {
      _onTelemetryReceived(d, s);
    });
    _mockService.startGenerating(s.activeNodeId);
  }

  void _stopSerial() {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _consoleSub?.cancel();
    _consoleSub = null;
    _serialService.disconnect();
  }

  void _stopMock() {
    _mockTelemetrySub?.cancel();
    _mockTelemetrySub = null;
    _mockService.stopGenerating();
  }

  void _startMqtt(GatewayStateProvider s) {
    _mqttService.connectWithConfig(
      host: s.mqttHost,
      port: s.mqttPort,
      username: s.mqttUsername,
      password: s.mqttPassword,
    );
  }

  void _stopMqtt() {
    _mqttService.disconnect();
  }

  void _toggleSerial(GatewayStateProvider s) {
    if (s.isSerialConnected) {
      _stopSerial();
      s.setSerialConnected(false);
      _startMock(s);
    } else {
      _startSerial(s);
    }
  }

  void _toggleMqtt(GatewayStateProvider s) {
    if (s.isMqttConnected) {
      _stopMqtt();
      s.setMqttConnected(false);
    } else {
      s.setMqttConnected(true);
      _startMqtt(s);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _stopSerial();
    _stopMock();
    _mqttStateSub?.cancel();
    _mqttLogSub?.cancel();
    _mqttService.dispose();
    _serialService.dispose();
    _mockService.dispose();
    super.dispose();
  }

  // Indonesian Date Formatter for Clock Widget
  String _formatIndoDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$day, ${dt.day} $month ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh.$mm.$ss';
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<GatewayStateProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Row(
        children: [
          // ─── LEFT SIDEBAR (Matching reference exactly) ───
          Container(
            width: 230,
            decoration: const BoxDecoration(
              color: AppTheme.sidebarBg,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Title
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AQUANODE',
                          style: TextStyle(color: AppTheme.t1, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        Text(
                          'EDGE - GATEWAY 01',
                          style: TextStyle(color: AppTheme.t3, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Clock Widget (Premium soft-green tint card)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light green tint
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(_currentTime),
                        style: const TextStyle(
                          color: AppTheme.deepGreen,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatIndoDate(_currentTime),
                        style: const TextStyle(
                          color: AppTheme.deepGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Menu Section Title
                const Text(
                  'MENU',
                  style: TextStyle(
                    color: AppTheme.t3,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Menu list: Dashboard
                _sidebarMenuItem(
                  index: 0,
                  icon: Icons.grid_view_outlined,
                  label: 'Dashboard',
                ),
                const SizedBox(height: 6),

                // Menu list: Settings
                _sidebarMenuItem(
                  index: 1,
                  icon: Icons.settings_outlined,
                  label: 'Pengaturan',
                ),

                const Spacer(),

                // Connection indicator anchored to bottom
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: s.isSerialConnected ? AppTheme.accentGreen : AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.isSerialConnected ? 'LoRa Terhubung' : 'LoRa Terputus',
                      style: const TextStyle(
                        color: AppTheme.t1,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<int>(
                  valueListenable: _bufferService.pendingCountNotifier,
                  builder: (context, count, child) {
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: count > 0 ? const Color(0xFFFF9800) : AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          count > 0 ? 'Buffer: $count Pending' : 'Buffer SQLite Ready',
                          style: TextStyle(
                            color: count > 0 ? const Color(0xFFFF9800) : AppTheme.t2,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ─── MAIN PANEL AREA (Right) ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Index 0: Dashboard view
                  _buildDashboardView(s),

                  // Index 1: Settings view
                  SettingsPanel(
                    state: s,
                    onToggleSerial: () => _toggleSerial(s),
                    onToggleMqtt: () => _toggleMqtt(s),
                    onSaved: () {
                      setState(() {
                        _selectedIndex = 0; // Automatically return to dashboard
                      });
                      if (s.isSerialConnected) {
                        _startSerial(s);
                      } else {
                        _startMock(s);
                      }
                      if (s.isMqttConnected) {
                        _startMqtt(s);
                      } else {
                        _stopMqtt();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarMenuItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool active = _selectedIndex == index;

    return Material(
      color: active ? AppTheme.deepGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppTheme.t2,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.t2,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView(GatewayStateProvider s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ringkasan Sensor',
                  style: TextStyle(color: AppTheme.t1, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pemantauan kualitas air secara real-time - Node ${s.activeNodeId}',
                  style: const TextStyle(color: AppTheme.t3, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '6 sensor aktif',
                    style: TextStyle(
                      color: AppTheme.deepGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Upper Section: Telemetry Grid + Video Feed
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3x2 Sensor Grid
              Expanded(
                flex: 5,
                child: TelemetryPanel(data: _currentData),
              ),
              const SizedBox(width: 12),
              // CCTV Camera aspect-ratio matched on the right
              Expanded(
                flex: 3,
                child: VideoPanel(rtspUrl: s.rtspUrl, cameraName: 'CCTV-TAMBAK-01'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lower Section: JSON payload console log
        Expanded(
          flex: 4,
          child: ConsolePanel(
            logs: _consoleLogs,
            onClear: () => setState(() => _consoleLogs.clear()),
          ),
        ),
      ],
    );
  }
}
