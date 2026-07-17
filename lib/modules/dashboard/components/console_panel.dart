import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';

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
  final ScrollController _sc = ScrollController();

  @override
  void didUpdateWidget(ConsolePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length > oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) {
          _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Light theme)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 12, color: AppTheme.accent),
                const SizedBox(width: 6),
                const Text(
                  'Serial Console',
                  style: TextStyle(color: AppTheme.t1, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.logs.length}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClear,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline, size: 12, color: AppTheme.t2),
                      SizedBox(width: 3),
                      Text('Clear', style: TextStyle(color: AppTheme.t2, fontSize: 9, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body (Light theme log entries)
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text('Awaiting LoRa data…', style: TextStyle(color: AppTheme.t3, fontSize: 10)),
                  )
                : ListView.builder(
                    controller: _sc,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.logs.length,
                    itemBuilder: (_, i) {
                      final log = widget.logs[i];
                      final badgeColor = log.isValid ? AppTheme.ok : AppTheme.danger;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '[${_fmt(log.timestamp)}]',
                                  style: const TextStyle(color: AppTheme.t3, fontFamily: 'monospace', fontSize: 9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  log.nodeId,
                                  style: const TextStyle(color: AppTheme.t2, fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    log.isValid ? 'OK' : 'ERR',
                                    style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    log.details,
                                    style: const TextStyle(color: AppTheme.t3, fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              log.hexString,
                              style: TextStyle(
                                color: log.isValid ? AppTheme.t1 : AppTheme.danger,
                                fontFamily: 'monospace',
                                fontSize: 9,
                                height: 1.3,
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

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
