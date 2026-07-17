import 'package:flutter/material.dart';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/theme/app_theme.dart';

class TelemetryPanel extends StatelessWidget {
  final TelemetryData? data;

  const TelemetryPanel({super.key, this.data});

  @override
  Widget build(BuildContext context) {
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
          value: data != null ? data!.dissolvedOxygen.toStringAsFixed(1) : '—',
          unit: 'mg/L',
          trend: '1.6%',
          isPositive: true,
          statusColor: AppTheme.ok,
        ),
        _sensorCard(
          icon: Icons.science_outlined,
          label: 'PH LEVEL',
          value: data != null ? data!.ph.toStringAsFixed(2) : '—',
          unit: 'pH',
          trend: '0.9%',
          isPositive: true,
          statusColor: AppTheme.ok,
        ),
        _sensorCard(
          icon: Icons.grid_view_outlined,
          label: 'TOTAL DISSOLVED SOLIDS',
          value: data != null ? data!.tds.toStringAsFixed(0) : '—',
          unit: 'ppm',
          trend: '0.0%',
          isNeutral: true,
          statusColor: AppTheme.ok,
        ),
        _sensorCard(
          icon: Icons.thermostat_outlined,
          label: 'SUHU',
          value: data != null ? data!.temperature.toStringAsFixed(1) : '—',
          unit: '°C',
          trend: '1.2%',
          isPositive: false,
          statusColor: AppTheme.ok,
        ),
        _sensorCard(
          icon: Icons.opacity_outlined,
          label: 'TURBIDITY',
          value: data != null ? data!.turbidity.toStringAsFixed(1) : '—',
          unit: 'NTU',
          trend: '0.7%',
          isPositive: true,
          statusColor: AppTheme.ok,
        ),
        _sensorCard(
          icon: Icons.waves_outlined,
          label: 'FLOW RATE',
          value: data != null ? data!.flowSpeed.toStringAsFixed(1) : '—',
          unit: 'L/min',
          trend: '0.3%',
          isPositive: false,
          statusColor: AppTheme.ok,
        ),
      ],
    );
  }

  Widget _sensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String trend,
    bool isPositive = true,
    bool isNeutral = false,
    required Color statusColor,
  }) {
    Color trendColor = isNeutral
        ? AppTheme.t3
        : (isPositive ? AppTheme.accentGreen : AppTheme.danger);
    IconData trendIcon = isNeutral
        ? Icons.trending_flat
        : (isPositive ? Icons.trending_up : Icons.trending_down);

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
          // Top row: Icon + Green dot indicator
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
                width: 5,
                height: 5,
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
                style: const TextStyle(
                  color: AppTheme.t1,
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

          // Bottom row: update status and trend percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'diperbarui baru saja',
                style: TextStyle(color: AppTheme.t3, fontSize: 8, fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 10, color: trendColor),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
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
