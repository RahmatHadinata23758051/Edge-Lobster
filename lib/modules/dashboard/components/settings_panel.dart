import 'package:flutter/material.dart';
import '../../../../core/services/gateway_state_provider.dart';
import '../../../../core/services/serial_port_service.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsPanel extends StatefulWidget {
  final GatewayStateProvider state;
  final VoidCallback onSaved;
  final VoidCallback onToggleSerial;
  final VoidCallback? onToggleMqtt;

  const SettingsPanel({
    super.key,
    required this.state,
    required this.onSaved,
    required this.onToggleSerial,
    this.onToggleMqtt,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late String _port;
  late int _baud;
  late TextEditingController _nodeController;
  late TextEditingController _rtspController;
  late TextEditingController _mqttHostController;
  late TextEditingController _mqttPortController;
  late TextEditingController _mqttUserController;
  late TextEditingController _mqttPassController;

  @override
  void initState() {
    super.initState();
    _port = widget.state.activePort;
    _baud = widget.state.baudRate;
    _nodeController = TextEditingController(text: widget.state.activeNodeId);
    _rtspController = TextEditingController(text: widget.state.rtspUrl);
    _mqttHostController = TextEditingController(text: widget.state.mqttHost);
    _mqttPortController = TextEditingController(text: widget.state.mqttPort.toString());
    _mqttUserController = TextEditingController(text: widget.state.mqttUsername);
    _mqttPassController = TextEditingController(text: widget.state.mqttPassword);
  }

  @override
  void dispose() {
    _nodeController.dispose();
    _rtspController.dispose();
    _mqttHostController.dispose();
    _mqttPortController.dispose();
    _mqttUserController.dispose();
    _mqttPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availablePorts = List.from(SerialPortService.getAvailablePorts());
    if (!availablePorts.contains(_port)) {
      availablePorts.add(_port);
    }

    final List<int> standardBauds = [4800, 9600, 19200, 38400, 57600, 115200];
    if (!standardBauds.contains(_baud)) {
      standardBauds.add(_baud);
      standardBauds.sort();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Header (Matching Dashboard Layout) ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengaturan Gateway',
                  style: TextStyle(color: AppTheme.t1, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Konfigurasi port serial, broker MQTT, serta koneksi integrasi API',
                  style: TextStyle(color: AppTheme.t3, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Sistem Siap',
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

        // ─── Main Form Container Card ───
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Connection Toggles
                        _sectTitle(Icons.online_prediction, 'KONEKSI & STATUS AKTIF'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _connectionButton(
                              icon: Icons.usb,
                              label: 'Serial Port',
                              active: widget.state.isSerialConnected,
                              onPressed: widget.onToggleSerial,
                            ),
                            const SizedBox(width: 12),
                            _connectionButton(
                              icon: Icons.cloud_sync,
                              label: 'MQTT Broker',
                              active: widget.state.isMqttConnected,
                              onPressed: widget.onToggleMqtt ?? widget.state.toggleMqtt,
                            ),
                            const SizedBox(width: 12),
                            _connectionButton(
                              icon: Icons.language,
                              label: 'API Cloud Sync',
                              active: widget.state.isInternetConnected,
                              onPressed: widget.state.toggleInternet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Serial Config
                        _sectTitle(Icons.usb, 'SERIAL PORT CONFIG'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdownField<String>(
                                label: 'Pilihan Port',
                                value: _port,
                                items: availablePorts.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _port = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _dropdownField<int>(
                                label: 'Baud Rate',
                                value: _baud,
                                items: standardBauds.map((b) => DropdownMenuItem(value: b, child: Text('$b bps', style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _baud = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // MQTT Config
                        _sectTitle(Icons.cloud_sync, 'MQTT BROKER CONFIG'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _textField(label: 'Host Broker', controller: _mqttHostController),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _textField(label: 'Port', controller: _mqttPortController),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(label: 'Username', controller: _mqttUserController),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _textField(label: 'Password', controller: _mqttPassController, obscure: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Node & CCTV Config
                        _sectTitle(Icons.sensors, 'NODE & CCTV CAMERA'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(label: 'Monitored Node ID', controller: _nodeController),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _textField(label: 'RTSP CCTV URL', controller: _rtspController),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions Footer
                const SizedBox(height: 16),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final mqttPortValue = int.tryParse(_mqttPortController.text) ?? 1883;

                        widget.state.updateSettings(
                          activePort: _port,
                          baudRate: _baud,
                          activeNodeId: _nodeController.text,
                          rtspUrl: _rtspController.text,
                          mqttHost: _mqttHostController.text,
                          mqttPort: mqttPortValue,
                          mqttUsername: _mqttUserController.text,
                          mqttPassword: _mqttPassController.text,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengaturan berhasil disimpan & diterapkan.'),
                            backgroundColor: AppTheme.primaryGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        widget.onSaved();
                      },
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('Simpan Perubahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _connectionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: active ? Colors.white : AppTheme.t2),
        label: Text(
          active ? '$label (Aktif)' : '$label (Nonaktif)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.t2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? AppTheme.primaryGreen : Colors.transparent,
          side: BorderSide(color: active ? AppTheme.primaryGreen : AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _sectTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGreen),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.t2, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.card,
          style: const TextStyle(color: AppTheme.t1, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.t2, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: AppTheme.t1, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
