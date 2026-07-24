import 'package:flutter/material.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/theme/app_theme.dart';

class TelemetryPanel extends StatelessWidget {
  final TelemetryData? data;
  final bool isSerialConnected;

  const TelemetryPanel({
    super.key,
    this.data,
    this.isSerialConnected = true,
  });

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = isSerialConnected && data != null;

    final String statusText = !isSerialConnected
        ? 'Serial Nonaktif'
        : (data != null ? 'Diperbarui ${_formatTime(data!.timestamp)}' : 'Menunggu Data Device');

    final Color statusColor = isOnline ? AppTheme.ok : AppTheme.t3;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _sensorCard(
          icon: Icons.water_drop_outlined,
          label: 'DISSOLVED OXYGEN',
          value: isOnline ? data!.dissolvedOxygen.toStringAsFixed(1) : '—',
          unit: isOnline ? 'mg/L' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
        _sensorCard(
          icon: Icons.science_outlined,
          label: 'PH LEVEL',
          value: isOnline ? data!.ph.toStringAsFixed(2) : '—',
          unit: isOnline ? 'pH' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
        _sensorCard(
          icon: Icons.grid_view_outlined,
          label: 'TOTAL DISSOLVED SOLIDS',
          value: isOnline ? data!.tds.toStringAsFixed(0) : '—',
          unit: isOnline ? 'ppm' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
        _sensorCard(
          icon: Icons.thermostat_outlined,
          label: 'SUHU',
          value: isOnline ? data!.temperature.toStringAsFixed(1) : '—',
          unit: isOnline ? '°C' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
        _sensorCard(
          icon: Icons.opacity_outlined,
          label: 'TURBIDITY',
          value: isOnline ? data!.turbidity.toStringAsFixed(1) : '—',
          unit: isOnline ? 'NTU' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
        _sensorCard(
          icon: Icons.waves_outlined,
          label: 'FLOW RATE',
          value: isOnline ? data!.flowSpeed.toStringAsFixed(1) : '—',
          unit: isOnline ? 'L/min' : '',
          statusText: statusText,
          isOnline: isOnline,
          statusColor: statusColor,
        ),
      ],
    );
  }

  Widget _sensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String statusText,
    required bool isOnline,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row: Icon + Green/Gray status dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: AppTheme.t2),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Label
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.t3,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          // Value + Unit
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isOnline ? AppTheme.t1 : AppTheme.t3,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(
                    color: AppTheme.t3,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          // Divider
          const SizedBox(height: 6),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 6),

          // Bottom row: update status text and real device indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: isOnline ? AppTheme.t2 : AppTheme.t3,
                  fontSize: 8,
                  fontWeight: isOnline ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.sensors : Icons.sensors_off,
                    size: 10,
                    color: isOnline ? AppTheme.accentGreen : AppTheme.t3,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isOnline ? 'Real' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? AppTheme.accentGreen : AppTheme.t3,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

