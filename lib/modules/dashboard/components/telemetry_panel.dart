import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/models/telemetry_data.dart';
import '../../../../core/theme/app_theme.dart';

class TelemetryPanel extends StatelessWidget {
  final TelemetryData? data;

  const TelemetryPanel({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    final String prettyJson = data != null ? encoder.convert(data!.toJson()) : 'Awaiting incoming LoRa telemetry packet...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Info bar: node / cage / gps / battery ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              _info('Node', data?.serialNumber ?? '—'),
              _sep(),
              _info('Cage', data?.cageCode ?? '—'),
              _sep(),
              _info('GPS', data != null ? '${data!.latitude.toStringAsFixed(4)}, ${data!.longitude.toStringAsFixed(4)}' : '—'),
              _sep(),
              _info(
                'Battery',
                data != null ? '${data!.batteryVoltage}V · ${data!.batteryCurrent}A' : '—',
                color: _batColor(data?.batteryVoltage),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── 6 ultra-compact cards in a 3-column x 2-row grid (fixed height) ──
        SizedBox(
          height: 132,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _tile(Icons.thermostat_outlined, 'Temp', data != null ? '${data!.temperature}/${data!.ambientTemperature}' : '—', '°C', _tempStatus(data?.temperature)),
              _tile(Icons.science_outlined, 'pH', data != null ? '${data!.ph}' : '—', '', _phStatus(data?.ph)),
              _tile(Icons.water_drop_outlined, 'DO', data != null ? '${data!.dissolvedOxygen}' : '—', 'mg/L', _doStatus(data?.dissolvedOxygen)),
              _tile(Icons.water_outlined, 'TDS', data != null ? data!.tds.toStringAsFixed(0) : '—', 'ppm', _tdsStatus(data?.tds)),
              _tile(Icons.opacity, 'Turbidity', data != null ? '${data!.turbidity}' : '—', 'NTU', _turbStatus(data?.turbidity)),
              _tile(Icons.waves, 'Flow', data != null ? '${data!.flowSpeed}' : '—', 'm/s', _flowStatus(data?.flowSpeed)),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Raw JSON Payload Viewer (Takes remaining vertical space) ──
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // JSON panel header
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.code, size: 12, color: AppTheme.accent),
                      SizedBox(width: 6),
                      Text(
                        'Latest JSON Payload (LoRa Parser)',
                        style: TextStyle(color: AppTheme.t1, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // JSON panel code editor-like box
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        prettyJson,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.t3, fontSize: 8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(color: color ?? AppTheme.t1, fontSize: 10, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sep() => Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppTheme.border);

  Widget _tile(IconData icon, String label, String value, String unit, _St st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // top: icon + label + status dot
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.t3),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppTheme.t2, fontSize: 9, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: st.c, shape: BoxShape.circle),
              ),
            ],
          ),
          // bottom: value + unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(color: AppTheme.t1, fontSize: 16, fontWeight: FontWeight.w700, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(color: AppTheme.t3, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _St _tempStatus(double? v) => v == null ? _St.na : (v < 25 || v > 30 ? _St.warn : _St.ok);
  _St _phStatus(double? v) => v == null ? _St.na : (v < 7.5 || v > 8.5 ? _St.warn : _St.ok);
  _St _doStatus(double? v) => v == null ? _St.na : (v < 5 ? _St.bad : v < 6 ? _St.warn : _St.ok);
  _St _tdsStatus(double? v) => v == null ? _St.na : (v < 100 || v > 1000 ? _St.warn : _St.ok);
  _St _turbStatus(double? v) => v == null ? _St.na : (v > 15 ? _St.bad : _St.ok);
  _St _flowStatus(double? v) => v == null ? _St.na : (v < 0.1 || v > 0.5 ? _St.warn : _St.ok);
  Color _batColor(double? v) => v == null ? AppTheme.t3 : v < 11.8 ? AppTheme.danger : v < 12.2 ? AppTheme.warn : AppTheme.ok;
}

class _St {
  final String t;
  final Color c;
  const _St(this.t, this.c);
  static const ok = _St('OK', AppTheme.ok);
  static const warn = _St('WARN', AppTheme.warn);
  static const bad = _St('BAD', AppTheme.danger);
  static const na = _St('NA', AppTheme.off);
}
