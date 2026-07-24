import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App Name and Node Name
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.developer_board, color: Color(0xFF0D9D1B), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edge Lobsense',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Lobster Sensing System',
                    style: TextStyle(
                      color: Color(0xFF0D9D1B),
                      fontWeight: FontWeight.bold,
                      fontSize: 8.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 16,
                color: const Color(0xFF334155),
              ),
              const SizedBox(width: 16),
              Text(
                'NODE: $activeNode',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // Right: Connection Status Indicators
          Row(
            children: [
              _buildIndicator(
                label: 'SERIAL RX',
                isConnected: isSerialConnected,
                info: activePort,
              ),
              const SizedBox(width: 24),
              _buildIndicator(
                label: 'MQTT BROKER',
                isConnected: isMqttConnected,
                info: 'MQTT-V2',
              ),
              const SizedBox(width: 24),
              _buildIndicator(
                label: 'CLOUD API',
                isConnected: isInternetConnected,
                info: 'SYNC',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required String label,
    required bool isConnected,
    required String info,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicator LED dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              isConnected ? info : 'OFFLINE',
              style: TextStyle(
                color: isConnected ? const Color(0xFF94A3B8) : const Color(0xFFEF4444).withValues(alpha: 0.8),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
