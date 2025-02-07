import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'adaptive_video_player.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? previewUrl;
  final String? hlsUrl;
  final String? nextVideoUrl;
  final String? nextPreviewUrl;
  final String? nextHlsUrl;

  // Static cache to store prefetched VideoPlayerControllers keyed by video URL
  static final Map<String, VideoPlayerController> _prefetchCache = {};

  // Maximum number of controllers to keep in cache
  static const int _maxCacheSize = 2;

  // Debug method to log cache state
  static void _logCacheState() {
    debugPrint('Cache state - URLs present: ${_prefetchCache.keys.toList()}');
  }

  // Method to clean up old cached controllers
  static void _cleanCache() {
    if (_prefetchCache.length > _maxCacheSize) {
      debugPrint('Cache cleanup: removing old controllers');
      final controllersToRemove =
          _prefetchCache.entries.take(_prefetchCache.length - _maxCacheSize);
      for (final entry in controllersToRemove) {
        debugPrint('Disposing cached controller for URL: ${entry.key}');
        entry.value.dispose();
        _prefetchCache.remove(entry.key);
      }
    }
  }

  // Method to dispose all cached controllers
  static void disposeCache() {
    debugPrint('Disposing all cached controllers');
    for (final controller in _prefetchCache.values) {
      controller.dispose();
    }
    _prefetchCache.clear();
  }

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.previewUrl,
    this.hlsUrl,
    this.nextVideoUrl,
    this.nextPreviewUrl,
    this.nextHlsUrl,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  bool _isInitialized = false;
  int _loadDuration = 0; // Time in milliseconds taken to load the video
  bool _wasPrefetched = false; // Whether the controller was loaded from cache

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing player for URL: ${widget.videoUrl}');
    debugPrint('Preview URL available: ${widget.previewUrl != null}');
    debugPrint('HLS URL available: ${widget.hlsUrl != null}');
    FeedVideoPlayer._logCacheState();
    _setupVideoPlayer();
  }

  Future<void> _setupVideoPlayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    setState(() {
      _isInitialized = true;
      _wasPrefetched = false;
    });

    stopwatch.stop();
    setState(() {
      _loadDuration = stopwatch.elapsedMilliseconds;
    });

    // Prefetch next video if available
    if (widget.nextVideoUrl != null ||
        widget.nextPreviewUrl != null ||
        widget.nextHlsUrl != null) {
      debugPrint('Starting prefetch for next video');
      _prefetchNextVideo();
    }
  }

  void _prefetchNextVideo() {
    // Clean up old cached controllers before prefetching new one
    FeedVideoPlayer._cleanCache();
    debugPrint('Prefetching completed');
  }

  @override
  void dispose() {
    debugPrint('Disposing player for: ${widget.videoUrl}');
    // Clean up any cached controllers that are too old
    FeedVideoPlayer._cleanCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        AdaptiveVideoPlayer(
          videoUrl: widget.videoUrl,
          previewUrl: widget.previewUrl,
          hlsUrl: widget.hlsUrl,
          autoPlay: true,
          looping: true,
        ),
        // Temporary UI indicator overlay for performance measurements
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(4),
            color: Colors.black54,
            child: Text(
              _wasPrefetched
                  ? 'Prefetched in ${_loadDuration}ms'
                  : 'Loaded fresh in ${_loadDuration}ms',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
