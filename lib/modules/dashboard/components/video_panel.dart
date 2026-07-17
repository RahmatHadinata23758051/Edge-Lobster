import 'package:flutter/material.dart';
import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/theme/app_theme.dart';

class VideoPanel extends StatefulWidget {
  final String rtspUrl;
  final String cameraName;

  const VideoPanel({super.key, required this.rtspUrl, required this.cameraName});

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  Player? _player;
  VideoController? _controller;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _initPlayer() {
    try {
      final p = Player();
      final c = VideoController(p);
      setState(() { _player = p; _controller = c; _hasError = false; });
      p.open(Media(widget.rtspUrl));
    } catch (e) {
      setState(() { _hasError = true; _errorMessage = 'libmpv not available'; });
    }
  }

  @override
  void didUpdateWidget(VideoPanel old) {
    super.didUpdateWidget(old);
    if (old.rtspUrl != widget.rtspUrl) {
      if (_player != null && !_hasError) {
        try { _player!.open(Media(widget.rtspUrl)); } catch (_) { setState(() => _hasError = true); }
      } else { _initPlayer(); }
    }
  }

  @override
  void dispose() { _timer?.cancel(); _player?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_hasError && _controller != null)
            Video(controller: _controller!)
          else
            _fallback(),

          // OSD top-left
          Positioned(
            top: 8, left: 8,
            child: _osd(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('REC ${widget.cameraName}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
              ],
            )),
          ),

          // OSD top-right
          Positioned(
            top: 8, right: 8,
            child: _osd(Text(_ts(_now), style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
          ),

          // OSD bottom-left
          Positioned(
            bottom: 8, left: 8,
            child: _osd(Text(
              _hasError ? 'FALLBACK' : 'RTSP LIVE',
              style: TextStyle(color: _hasError ? AppTheme.danger : AppTheme.ok, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700),
            )),
          ),
        ],
      ),
    );
  }

  Widget _osd(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
    child: child,
  );

  Widget _fallback() {
    return Container(
      color: const Color(0xFF020617),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Color(0xFF334155), size: 28),
            const SizedBox(height: 8),
            const Text('Live Camera Feed', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(widget.rtspUrl, style: const TextStyle(color: Color(0xFF475569), fontFamily: 'monospace', fontSize: 9)),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
            ],
          ],
        ),
      ),
    );
  }

  String _ts(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
}
