import 'package:flutter/material.dart';
import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPanel extends StatefulWidget {
  final String rtspUrl;
  final String cameraName;

  const VideoPanel({
    super.key,
    required this.rtspUrl,
    required this.cameraName,
  });

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
    _startTimer();
  }

  void _initPlayer() {
    try {
      final player = Player();
      final controller = VideoController(player);

      setState(() {
        _player = player;
        _controller = controller;
        _hasError = false;
      });

      player.open(Media(widget.rtspUrl));
    } catch (e) {
      // Tangani jika library native libmpv tidak terinstal
      setState(() {
        _hasError = true;
        _errorMessage = 'Native libmpv missing. Using hardware fallback feed.';
      });
      debugPrint('MediaKit initialization fallback: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(VideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rtspUrl != widget.rtspUrl) {
      if (_player != null && !_hasError) {
        try {
          _player!.open(Media(widget.rtspUrl));
        } catch (e) {
          setState(() {
            _hasError = true;
          });
        }
      } else {
        _initPlayer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player or Fallback visual representation
          if (!_hasError && _controller != null)
            Video(controller: _controller!)
          else
            _buildFallbackStream(),

          // 2. Overlay: Camera Info (Industrial OSD)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                border: Border.all(color: const Color(0xFF334155), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REC ${widget.cameraName.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Overlay: Timestamp (Industrial OSD)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                border: Border.all(color: const Color(0xFF334155), width: 1.0),
              ),
              child: Text(
                _formatTimestamp(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),

          // 4. Overlay: Technical / Stream Details (Bottom Left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'STREAM: RTSP H.264',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _hasError ? 'MODE: SYNTHETIC FALLBACK' : 'MODE: HARDWARE DIRECT',
                    style: TextStyle(
                      color: _hasError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackStream() {
    // Beautiful mock camera feed without using generic images or clip art
    return Container(
      color: const Color(0xFF020617),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle grids to feel industrial
          Opacity(
            opacity: 0.1,
            child: GridPaper(
              color: Colors.white,
              interval: 40,
              subdivisions: 1,
            ),
          ),
          
          // Simulated CCTV Lens outline & crosshair
          Opacity(
            opacity: 0.2,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _CctvCrosshairPainter(),
            ),
          ),

          // Fallback info text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Color(0xFF475569),
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'LIVE CAMERA FEED',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.rtspUrl,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.0),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$min:$sec';
  }
}

class _CctvCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw central circle
    canvas.drawCircle(center, 24, paint);
    canvas.drawCircle(center, radius, paint);

    // Draw crosshair lines
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx - 40, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 40, center.dy), Offset(center.dx + radius, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy - 40), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 40), Offset(center.dx, center.dy + radius), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
