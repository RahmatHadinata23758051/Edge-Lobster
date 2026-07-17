import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  final bool isSerialConnected;
  final bool isMqttConnected;
  final bool isInternetConnected;
  final String activePort;
  final String activeNode;

  const StatusBar({
    super.key,
    required this.isSerialConnected,
    required this.isMqttConnected,
    required this.isInternetConnected,
    required this.activePort,
    required this.activeNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.sensors, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Lobsense',
            style: TextStyle(color: AppTheme.t1, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(width: 4),
          const Text(
            'Edge Gateway',
            style: TextStyle(color: AppTheme.t3, fontWeight: FontWeight.w400, fontSize: 14),
          ),

          const Spacer(),

          // Connection pills
          _pill('Serial', isSerialConnected, activePort),
          const SizedBox(width: 6),
          _pill('MQTT', isMqttConnected, null),
          const SizedBox(width: 6),
          _pill('Cloud', isInternetConnected, null),
        ],
      ),
    );
  }

  Widget _pill(String label, bool active, String? sub) {
    final color = active ? AppTheme.ok : AppTheme.t3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppTheme.ok.withValues(alpha: 0.08) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            sub != null && active ? '$label · $sub' : label,
            style: TextStyle(color: active ? AppTheme.ok : AppTheme.t3, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
