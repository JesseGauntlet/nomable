import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? previewUrl; // Add preview URL parameter
  final String? nextVideoUrl;
  final String? nextPreviewUrl; // Add next preview URL parameter

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
    this.nextVideoUrl,
    this.nextPreviewUrl,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  int _loadDuration = 0; // Time in milliseconds taken to load the video
  bool _wasPrefetched = false; // Whether the controller was loaded from cache
  bool _isUsingPreview = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing player for URL: ${widget.videoUrl}');
    debugPrint('Preview URL available: ${widget.previewUrl != null}');
    FeedVideoPlayer._logCacheState();
    _setupVideoPlayer();
  }

  // New method: Check for a prefetched controller, or initialize normally
  Future<void> _setupVideoPlayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    // Determine which URL to use (preview or full quality)
    final urlToUse = widget.previewUrl ?? widget.videoUrl;
    _isUsingPreview = widget.previewUrl != null;

    debugPrint('Setting up player for: $urlToUse');
    debugPrint('Checking cache for URL: $urlToUse');
    FeedVideoPlayer._logCacheState();

    if (FeedVideoPlayer._prefetchCache.containsKey(urlToUse)) {
      debugPrint('Cache hit! Using prefetched controller for: $urlToUse');
      _controller = FeedVideoPlayer._prefetchCache.remove(urlToUse)!;
      _wasPrefetched = true;
      setState(() {
        _isInitialized = true;
      });
      _controller.setLooping(true);
      _controller.play();
    } else {
      debugPrint('Cache miss. Loading fresh for: $urlToUse');
      _wasPrefetched = false;
      await _initializeVideoPlayer(urlToUse);
    }

    stopwatch.stop();
    setState(() {
      _loadDuration = stopwatch.elapsedMilliseconds;
    });

    // Prefetch next video (preview if available)
    final nextUrlToUse = widget.nextPreviewUrl ?? widget.nextVideoUrl;
    if (nextUrlToUse != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(nextUrlToUse)) {
      debugPrint('Starting prefetch for next URL: $nextUrlToUse');
      _prefetchNextVideo(nextUrlToUse);
    }
  }

  // New method: Prefetch the next video's controller without auto-playing
  Future<void> _prefetchNextVideo(String videoUrl) async {
    // Clean up old cached controllers before prefetching new one
    FeedVideoPlayer._cleanCache();

    debugPrint('Beginning prefetch for: $videoUrl');
    VideoPlayerController prefetchedController =
        VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await prefetchedController.initialize();
      prefetchedController.setLooping(true);
      // Store the prefetched controller in the static cache for later use
      FeedVideoPlayer._prefetchCache[videoUrl] = prefetchedController;
      debugPrint('Successfully added to cache: $videoUrl');
      FeedVideoPlayer._logCacheState();
    } catch (e) {
      debugPrint('Error prefetching video for $videoUrl: $e');
      prefetchedController
          .dispose(); // Dispose controller if initialization fails
    }
  }

  // Fallback method to initialize the video player without prefetching
  Future<void> _initializeVideoPlayer(String url) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing controller for: ${widget.videoUrl}');
    _controller.dispose();

    // Clean up any cached controllers that are too old
    FeedVideoPlayer._cleanCache();

    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
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
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.black,
            child: Center(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
          ),
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
