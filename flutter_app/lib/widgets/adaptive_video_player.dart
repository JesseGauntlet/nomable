import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// A video player widget that supports both HLS and regular video playback.
/// It will use HLS when available and fall back to regular video playback.
class AdaptiveVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? hlsUrl;
  final String? previewUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;

  const AdaptiveVideoPlayer({
    super.key,
    required this.videoUrl,
    this.hlsUrl,
    this.previewUrl,
    this.autoPlay = true,
    this.looping = true,
    this.showControls = false,
  });

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _activeUrl;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Try HLS first if available
    if (widget.hlsUrl != null) {
      try {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl!));
        await _controller!.initialize();
        _setupChewieController();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _activeUrl = widget.hlsUrl;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error initializing HLS player: $e');
        _controller?.dispose();
        _controller = null;
      }
    }

    // Fall back to preview or original video if HLS fails or is not available
    try {
      final urlToUse = widget.previewUrl ?? widget.videoUrl;
      _controller = VideoPlayerController.networkUrl(Uri.parse(urlToUse));
      await _controller!.initialize();
      _setupChewieController();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _activeUrl = urlToUse;
        });
      }
    } catch (e) {
      debugPrint('Error initializing fallback player: $e');
      _controller?.dispose();
      _controller = null;
    }
  }

  void _setupChewieController() {
    if (_controller != null) {
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: _controller!.value.aspectRatio,
        showOptions: false,
        // Hide native controls on mobile but show on web
        showControlsOnInitialize: false,
        hideControlsTimer: const Duration(seconds: 2),
      );
    }
  }

  void togglePlayPause() {
    if (_controller?.value.isPlaying ?? false) {
      _controller?.pause();
    } else {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.showControls ? null : togglePlayPause,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
      ),
    );
  }
}
