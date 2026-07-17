import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
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

  String get utf8String {
    try {
      return utf8.decode(rawBytes);
    } catch (_) {
      return '';
    }
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
        color: AppTheme.terminalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Visual Tab Style matching screenshot exactly)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Row(
              children: [
                // Window Control dots (gray)
                const Row(
                  children: [
                    Text('● ● ●', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(width: 16),
                // Tab title
                const Text(
                  'raw_data_lora.json',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                // Blinking/Active status dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF238636), // Green
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'menerima paket',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                // Clear button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF8B949E)),
                  onPressed: widget.onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus Log',
                ),
              ],
            ),
          ),
          // Body (Beautiful highlighted logs)
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting telemetry streams...',
                      style: TextStyle(color: Color(0xFF484F58), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  )
                : ListView.builder(
                    controller: _sc,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.logs.length,
                    itemBuilder: (_, i) {
                      final log = widget.logs[i];
                      final lineNum = (i + 1).toString().padLeft(2, '0');
                      final jsonText = log.utf8String;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Line number (e.g. 01)
                            Text(
                              lineNum,
                              style: const TextStyle(
                                color: Color(0xFF484F58),
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Styled JSON content
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                  children: _highlightJson(jsonText),
                                ),
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

  /// Simple JSON Highlighter
  List<TextSpan> _highlightJson(String text) {
    if (text.isEmpty) return [const TextSpan(text: '')];

    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(
      r'("[^"]*")\s*(:)\s*|("[^"]*")|(\b[0-9.-]+\b)|(\b(true|false|null)\b)|([\{\}\[\],:])',
      multiLine: true,
    );

    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Color(0xFFC9D1D9)),
        ));
      }

      if (match.group(1) != null) {
        // Match key: "key":
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(color: Color(0xFF79C0FF)), // Light Blue
        ));
        spans.add(TextSpan(
          text: match.group(2) ?? ':',
          style: const TextStyle(color: Color(0xFFC9D1D9)),
        ));
      } else if (match.group(3) != null) {
        // Match string value: "value"
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(color: Color(0xFFA5D6FF)), // Greenish Blue
        ));
      } else if (match.group(4) != null) {
        // Match number value
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(color: Color(0xFFFF9485)), // Light orange
        ));
      } else if (match.group(5) != null) {
        // Match boolean/null
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(color: Color(0xFFFF7B72)), // Orange red
        ));
      } else if (match.group(7) != null) {
        // Match bracket / separator
        spans.add(TextSpan(
          text: match.group(7),
          style: const TextStyle(color: Color(0xFFC9D1D9)),
        ));
      }

      lastMatchEnd = match.end;
    }

    // Add trailing text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(color: Color(0xFFC9D1D9)),
      ));
    }

    return spans;
  }
}
