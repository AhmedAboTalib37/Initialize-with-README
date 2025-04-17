import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String details;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.details,
  });

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  late Duration _videoDuration;
  late Duration _currentPosition;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..addListener(_videoListener)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoDuration = _controller.value.duration;
          _currentPosition = _controller.value.position;
        });
        _controller.play();
        _isPlaying = true;
        // Hide controls after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading video: ${error.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _currentPosition = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
        // Hide controls after play
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }

  void _changePlaybackSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed >= 2.0 ? 0.5 : _playbackSpeed + 0.5;
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekToPosition(Duration position) {
    _controller.seekTo(position);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls && _isPlaying) {
        // Auto-hide controls after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(widget.title),
              backgroundColor: colorScheme.surface,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => setState(() => _isFullScreen = true),
                ),
              ],
            ),
      body: _isInitialized
          ? GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                fit: _isFullScreen ? StackFit.expand : StackFit.loose,
                children: [
                  // Video Player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio > 0
                          ? _controller.value.aspectRatio
                          : 16 / 9,
                      child: VideoPlayer(_controller),
                    ),
                  ),

                  // Overlay Controls
                  if (_showControls) ...[
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Play/Pause button
                    Positioned.fill(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 48,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                      ),
                    ),

                    // Top controls
                    Positioned(
                      top: _isFullScreen ? 16 : 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            if (_isFullScreen)
                              IconButton(
                                icon: const Icon(Icons.fullscreen_exit,
                                    color: Colors.white),
                                onPressed: () =>
                                    setState(() => _isFullScreen = false),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextButton(
                                onPressed: _changePlaybackSpeed,
                                child: Text(
                                  "${_playbackSpeed}x",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom controls
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            // Progress bar
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_currentPosition),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor: Colors.white54,
                                      thumbColor: colorScheme.primary,
                                      overlayColor:
                                          colorScheme.primary.withOpacity(0.2),
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _currentPosition.inMilliseconds
                                          .toDouble(),
                                      min: 0,
                                      max: _videoDuration.inMilliseconds
                                          .toDouble(),
                                      onChanged: (value) {
                                        setState(() {
                                          _currentPosition =
                                              Duration(milliseconds: value.toInt());
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        _seekToPosition(
                                            Duration(milliseconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(_videoDuration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!_isPlaying)
                    Positioned.fill(
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow,
                              size: 48, color: Colors.white),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Loading video...",
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
      // Video details section
      bottomNavigationBar: _isInitialized && !_isFullScreen
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.details,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}