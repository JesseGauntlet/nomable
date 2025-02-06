import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? nextVideoUrl; // Optional next video URL for prefetching

  // Static cache to store prefetched VideoPlayerControllers keyed by video URL
  static final Map<String, VideoPlayerController> _prefetchCache = {};

  // Debug method to log cache state
  static void _logCacheState() {
    debugPrint('Cache state - URLs present: ${_prefetchCache.keys.toList()}');
  }

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.nextVideoUrl,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  int _loadDuration = 0; // Time in milliseconds taken to load the video
  bool _wasPrefetched = false; // Whether the controller was loaded from cache

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing player for URL: ${widget.videoUrl}');
    debugPrint('Next video URL is: ${widget.nextVideoUrl}');
    FeedVideoPlayer._logCacheState();
    _setupVideoPlayer();
  }

  // New method: Check for a prefetched controller, or initialize normally
  Future<void> _setupVideoPlayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    debugPrint('Setting up player for: ${widget.videoUrl}');
    debugPrint('Checking cache for URL: ${widget.videoUrl}');
    FeedVideoPlayer._logCacheState();

    // Check if a prefetched controller exists for this videoUrl
    if (FeedVideoPlayer._prefetchCache.containsKey(widget.videoUrl)) {
      debugPrint(
          'Cache hit! Using prefetched controller for: ${widget.videoUrl}');
      _controller = FeedVideoPlayer._prefetchCache.remove(widget.videoUrl)!;
      _wasPrefetched = true; // Mark as loaded from prefetch cache
      setState(() {
        _isInitialized = true;
      });
      _controller.setLooping(true);
      _controller.play();
    } else {
      debugPrint('Cache miss. Loading fresh for: ${widget.videoUrl}');
      _wasPrefetched = false; // Loaded fresh
      await _initializeVideoPlayer();
    }

    // Stop the stopwatch and record the load duration
    stopwatch.stop();
    setState(() {
      _loadDuration = stopwatch.elapsedMilliseconds;
    });

    // Log before attempting to prefetch
    if (widget.nextVideoUrl != null) {
      debugPrint('Considering prefetch for next URL: ${widget.nextVideoUrl}');
      if (FeedVideoPlayer._prefetchCache.containsKey(widget.nextVideoUrl)) {
        debugPrint('Next URL already in cache: ${widget.nextVideoUrl}');
      } else {
        debugPrint('Starting prefetch for next URL: ${widget.nextVideoUrl}');
        _prefetchNextVideo(widget.nextVideoUrl!);
      }
    }
  }

  // New method: Prefetch the next video's controller without auto-playing
  Future<void> _prefetchNextVideo(String videoUrl) async {
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
    }
  }

  // Fallback method to initialize the video player without prefetching
  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
                  ? 'Prefetched in ${_loadDuration} ms'
                  : 'Loaded fresh in ${_loadDuration} ms',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
