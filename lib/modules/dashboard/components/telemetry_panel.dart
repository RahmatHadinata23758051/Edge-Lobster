import 'package:flutter/material.dart';
import '../../../../core/models/telemetry_data.dart';

class TelemetryPanel extends StatelessWidget {
  final TelemetryData? data;

  const TelemetryPanel({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Header
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'LORA SENSOR DATA',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          // Grid of Sensors
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildSensorTile(
                  label: 'WATER TEMPERATURE',
                  value: data != null ? '${data!.temperature}' : '--.-',
                  unit: '°C',
                  status: _getTemperatureStatus(data?.temperature),
                ),
                _buildSensorTile(
                  label: 'ACIDITY LEVEL (pH)',
                  value: data != null ? '${data!.ph}' : '--.-',
                  unit: 'pH',
                  status: _getPhStatus(data?.ph),
                ),
                _buildSensorTile(
                  label: 'DISSOLVED OXYGEN (DO)',
                  value: data != null ? '${data!.dissolvedOxygen}' : '--.-',
                  unit: 'mg/L',
                  status: _getDoStatus(data?.dissolvedOxygen),
                ),
                _buildSensorTile(
                  label: 'SALINITY / TDS',
                  value: data != null ? '${data!.salinity}' : '--.-',
                  unit: 'ppt',
                  status: _getSalinityStatus(data?.salinity),
                ),
                _buildSensorTile(
                  label: 'TURBIDITY (KEKERUHAN)',
                  value: data != null ? '${data!.turbidity}' : '--.-',
                  unit: 'NTU',
                  status: _getTurbidityStatus(data?.turbidity),
                ),
                _buildSensorTile(
                  label: 'WATER FLOW SPEED',
                  value: data != null ? '${data!.flowSpeed}' : '--.-',
                  unit: 'm/s',
                  status: _getFlowStatus(data?.flowSpeed),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Section: Power & System Details
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border.all(color: const Color(0xFF334155), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'POWER & SYSTEM METRICS',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSystemMetric(
                      label: 'BATTERY',
                      value: data != null ? '${data!.batteryVoltage} V' : '--.- V',
                      color: _getBatteryColor(data?.batteryVoltage),
                    ),
                    _buildSystemMetric(
                      label: 'SOLAR PANEL',
                      value: data != null ? '${data!.solarVoltage} V / ${data!.solarCurrent} A' : '--.- V / --.- A',
                      color: data != null && data!.solarVoltage > 5.0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                    _buildSystemMetric(
                      label: 'GPS COORDINATES',
                      value: data != null ? '${data!.latitude}, ${data!.longitude}' : '--.------, --.------',
                      color: Colors.blueAccent,
                      isMonospace: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTile({
    required String label,
    required String value,
    required String unit,
    required _SensorStatus status,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(
          color: status.borderColor,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                decoration: BoxDecoration(
                  color: status.bgColor,
                ),
                child: Text(
                  status.text,
                  style: TextStyle(
                    color: status.textColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMetric({
    required String label,
    required String value,
    required Color color,
    bool isMonospace = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: isMonospace ? 'monospace' : null,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Business logic thresholds (avoiding hardcoded magic numbers)
  _SensorStatus _getTemperatureStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value < 25.0 || value > 30.0) return _SensorStatus.critical('WARNING', const Color(0xFFEF4444));
    return _SensorStatus.normal('NORMAL');
  }

  _SensorStatus _getPhStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value < 7.5 || value > 8.5) return _SensorStatus.critical('WARNING', const Color(0xFFEF4444));
    return _SensorStatus.normal('NORMAL');
  }

  _SensorStatus _getDoStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value < 5.0) return _SensorStatus.critical('DANGER', const Color(0xFFEF4444));
    if (value < 6.0) return _SensorStatus.critical('WARNING', const Color(0xFFF59E0B));
    return _SensorStatus.normal('NORMAL');
  }

  _SensorStatus _getSalinityStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value < 28.0 || value > 35.0) return _SensorStatus.critical('WARNING', const Color(0xFFEF4444));
    return _SensorStatus.normal('NORMAL');
  }

  _SensorStatus _getTurbidityStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value > 10.0) return _SensorStatus.critical('HIGH', const Color(0xFFEF4444));
    return _SensorStatus.normal('NORMAL');
  }

  _SensorStatus _getFlowStatus(double? value) {
    if (value == null) return _SensorStatus.unknown();
    if (value < 0.1 || value > 0.5) return _SensorStatus.critical('WARNING', const Color(0xFFF59E0B));
    return _SensorStatus.normal('NORMAL');
  }

  Color _getBatteryColor(double? value) {
    if (value == null) return const Color(0xFF64748B);
    if (value < 11.8) return const Color(0xFFEF4444);
    if (value < 12.2) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}

class _SensorStatus {
  final String text;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _SensorStatus({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  factory _SensorStatus.normal(String text) {
    return _SensorStatus(
      text: text,
      textColor: const Color(0xFF10B981),
      bgColor: const Color(0xFF064E3B),
      borderColor: const Color(0xFF334155),
    );
  }

  factory _SensorStatus.critical(String text, Color color) {
    return _SensorStatus(
      text: text,
      textColor: color,
      bgColor: color.withOpacity(0.15),
      borderColor: color.withOpacity(0.5),
    );
  }

  factory _SensorStatus.unknown() {
    return const _SensorStatus(
      text: 'UNKNOWN',
      textColor: Color(0xFF64748B),
      bgColor: Color(0xFF1E293B),
      borderColor: Color(0xFF334155),
    );
  }
}
