import 'package:flutter/material.dart';
import 'dart:typed_data';

class ConsoleLog {
  final DateTime timestamp;
  final String nodeId;
  final Uint8List rawBytes;
  final bool isValid;
  final String details;

  ConsoleLog({
    required this.timestamp,
    required this.nodeId,
    required this.rawBytes,
    required this.isValid,
    required this.details,
  });

  String get hexString {
    return rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }
}

class ConsolePanel extends StatefulWidget {
  final List<ConsoleLog> logs;
  final VoidCallback onClear;

  const ConsolePanel({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ConsolePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto scroll ke bawah saat ada log baru masuk
    if (widget.logs.length > oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19), // Darker terminal background
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    const Text(
                      'RAW RX DATA STREAM (LORA)',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      color: const Color(0xFF0F172A),
                      child: Text(
                        '${widget.logs.length} PKTS',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 8,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onClear,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'CLEAR CONSOLE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Terminal Output
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text(
                      'AWAITING SERIAL LORA TRANSMISSION...',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: widget.logs.length,
                    itemBuilder: (context, index) {
                      final log = widget.logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header bar log: timestamp, node, status
                            Row(
                              children: [
                                Text(
                                  '[${_formatTime(log.timestamp)}]',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'NODE: ${log.nodeId}',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                  color: log.isValid ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                                  child: Text(
                                    log.isValid ? 'VALID' : 'CRC_ERR',
                                    style: TextStyle(
                                      color: log.isValid ? const Color(0xFF10B981) : const Color(0xFFF87171),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log.details,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Hex output
                            Text(
                              log.hexString,
                              style: TextStyle(
                                color: log.isValid ? const Color(0xFFCBD5E1) : const Color(0xFFF87171).withOpacity(0.8),
                                fontFamily: 'monospace',
                                fontSize: 10,
                                height: 1.3,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    final ms = (dt.millisecond).toString().padLeft(3, '0');
    return '$hour:$min:$sec.$ms';
  }
}
