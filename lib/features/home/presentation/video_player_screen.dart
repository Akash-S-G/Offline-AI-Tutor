import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Screen to play educational videos with playback controls
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    this.subtitle,
    this.description,
    super.key,
  });

  final String videoUrl;
  final String title;
  final String? subtitle;
  final String? description;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  double _playbackSpeed = 1.0;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      } else {
        _controller = VideoPlayerController.file(
          File(widget.videoUrl),
        );
      }

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      _controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Error loading video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _changePlaybackSpeed(double speed) {
    _controller?.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Speed: ${speed}x'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: _initError != null
          ? _buildErrorState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVideoPlayer(),
                  _buildControlsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_initError!),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return _isInitialized && _controller != null
        ? _VideoPlayerWidget(
            controller: _controller!,
          )
        : Container(
            height: 300,
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
  }

  Widget _buildControlsSection() {
    return Container(
      color: const Color(0xFFF7FCFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 12),
          if (_isInitialized && _controller != null) ...[
            _buildProgressBar(),
            const SizedBox(height: 16),
            _buildPlaybackControls(),
          ],
          const SizedBox(height: 24),
          if (widget.description != null && widget.description!.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description!,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
          ],
          if (_isInitialized && _controller != null) _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            min: 0,
            max: _controller!.value.duration.inMilliseconds.toDouble(),
            value: _controller!.value.position.inMilliseconds
                .toDouble()
                .clamp(0, _controller!.value.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              _controller!.seekTo(Duration(milliseconds: value.toInt()));
            },
            activeColor: const Color(0xFFFF6B35),
            inactiveColor: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(_controller!.value.position),
                style: const TextStyle(fontSize: 12)),
            Text(_formatDuration(_controller!.value.duration),
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PopupMenuButton<double>(
          onSelected: _changePlaybackSpeed,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 0.5, child: Text('0.5x')),
            PopupMenuItem(value: 0.75, child: Text('0.75x')),
            PopupMenuItem(value: 1.0, child: Text('1x')),
            PopupMenuItem(value: 1.25, child: Text('1.25x')),
            PopupMenuItem(value: 1.5, child: Text('1.5x')),
            PopupMenuItem(value: 2.0, child: Text('2x')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0B6E4F)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_playbackSpeed}x',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B6E4F),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subtitles: Coming soon'),
                duration: Duration(milliseconds: 500),
              ),
            );
          },
          icon: const Icon(Icons.closed_caption_rounded),
          label: const Text('CC'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B6E4F),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share: Coming soon'),
                duration: Duration(milliseconds: 500),
              ),
            );
          },
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B6E4F),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Duration',
              value: _formatDuration(_controller!.value.duration),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Current Time',
              value: _formatDuration(_controller!.value.position),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Resolution',
              value:
                  '${_controller!.value.size.width.toInt()}x${_controller!.value.size.height.toInt()}',
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(widget.controller),
              if (_showControls)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.5,
                      child: FloatingActionButton(
                        elevation: 0,
                        backgroundColor: Colors.white.withOpacity(0.7),
                        onPressed: () {
                          setState(() {
                            if (widget.controller.value.isPlaying) {
                              widget.controller.pause();
                            } else {
                              widget.controller.play();
                            }
                          });
                        },
                        child: Icon(
                          widget.controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
