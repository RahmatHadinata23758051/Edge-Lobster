import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.rtspUrl.trim().isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final p = Player();
      final c = VideoController(p);

      p.stream.error.listen((err) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });

      if (mounted) {
        setState(() {
          _player = p;
          _controller = c;
          _hasError = false;
        });
      }

      p.open(Media(widget.rtspUrl), play: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoPanel old) {
    super.didUpdateWidget(old);
    if (old.rtspUrl != widget.rtspUrl) {
      if (_player != null && !_hasError) {
        try {
          _player!.open(Media(widget.rtspUrl));
        } catch (_) {
          if (mounted) setState(() => _hasError = true);
        }
      } else {
        _initPlayer();
      }
    }
  }

  @override
  void dispose() {
    final player = _player;
    _player = null;
    _controller = null;
    if (player != null) {
      try {
        player.stop();
        player.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090C10),
        borderRadius: BorderRadius.circular(12),
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

          // Live indicator top center
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF090D16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.04,
            child: GridPaper(
              color: Colors.greenAccent,
              interval: 32,
              subdivisions: 1,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_outlined, color: Color(0xFF30363D), size: 36),
              const SizedBox(height: 12),
              Text(
                'KAMERA - Menunggu feed'.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
