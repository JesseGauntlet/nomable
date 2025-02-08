import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'adaptive_video_player.dart';
import 'package:chewie/chewie.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? previewUrl;
  final String? hlsUrl;
  final String? nextVideoUrl;
  final String? nextPreviewUrl;
  final String? nextHlsUrl;

  // Static cache to store prefetched controllers keyed by video URL
  static final Map<String, (VideoPlayerController, ChewieController?)>
      _prefetchCache = {};

  // Maximum number of controllers to keep in cache
  static const int _maxCacheSize =
      4; // Reduced back to 3 since we only prefetch next

  // Keep track of recently used URLs to implement LRU cache
  static final List<String> _recentlyUsedUrls = [];

  // Debug method to log cache state
  static void _logCacheState() {
    debugPrint('Cache state - URLs present: ${_prefetchCache.keys.toList()}');
    debugPrint('Recently used URLs: $_recentlyUsedUrls');
  }

  // Smarter cache cleanup: remove least recently used items
  static void _cleanLeastRecentlyUsed() {
    while (_prefetchCache.length >= _maxCacheSize &&
        _recentlyUsedUrls.isNotEmpty) {
      final lruUrl = _recentlyUsedUrls.removeAt(0); // Remove oldest URL
      if (_prefetchCache.containsKey(lruUrl)) {
        debugPrint('Removing least recently used URL from cache: $lruUrl');
        final controllers = _prefetchCache.remove(lruUrl)!;
        controllers.$2?.dispose();
        controllers.$1.dispose();
      }
    }
  }

  // Method to update recently used URLs
  static void _markUrlAsUsed(String url) {
    _recentlyUsedUrls.remove(url); // Remove if exists
    _recentlyUsedUrls.add(url); // Add to end (most recent)
    if (_recentlyUsedUrls.length > _maxCacheSize * 2) {
      // Keep list bounded
      _recentlyUsedUrls.removeAt(0);
    }
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
  int _loadDuration = 0;
  bool _wasPrefetched = false;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing player for URL: ${widget.videoUrl}');
    debugPrint('Preview URL available: ${widget.previewUrl != null}');
    debugPrint('HLS URL available: ${widget.hlsUrl != null}');
    FeedVideoPlayer._logCacheState();
    _setupVideoPlayer();
  }

  // Improved controller cleanup method that optionally skips cache cleanup
  void _cleanupControllers({bool preserveCache = false}) {
    if (!preserveCache) {
      debugPrint('Cleaning up controllers and cache');
      FeedVideoPlayer._cleanLeastRecentlyUsed();
    } else {
      debugPrint('Cleaning up only current controllers, preserving cache');
    }
    // Only dispose controllers if they were not prefetched
    if (!_wasPrefetched) {
      _chewieController?.dispose();
      _controller?.dispose();
    } else {
      debugPrint('Controllers are prefetched; preserving them in cache.');
    }
    _chewieController = null;
    _controller = null;
  }

  Future<void> _setupVideoPlayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Try to get prefetched controllers first
      String? urlToUse;
      if (widget.hlsUrl != null &&
          FeedVideoPlayer._prefetchCache.containsKey(widget.hlsUrl)) {
        urlToUse = widget.hlsUrl;
      } else if (widget.previewUrl != null &&
          FeedVideoPlayer._prefetchCache.containsKey(widget.previewUrl)) {
        urlToUse = widget.previewUrl;
      } else if (FeedVideoPlayer._prefetchCache.containsKey(widget.videoUrl)) {
        urlToUse = widget.videoUrl;
      }

      if (urlToUse != null) {
        debugPrint('Using prefetched controller for: $urlToUse');
        // Clean up existing local controllers but preserve the global cache; do not remove the cached controller
        _cleanupControllers(preserveCache: true);

        final cached = FeedVideoPlayer._prefetchCache[urlToUse]!;
        _controller = cached.$1;
        _chewieController = cached.$2;
        _wasPrefetched = true;
        FeedVideoPlayer._markUrlAsUsed(urlToUse); // Mark as recently used

        if (!(_controller!.value.isPlaying)) {
          await _controller!.play();
        }
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } else {
        // No cache hit, clean up everything and initialize new controllers
        _cleanupControllers(preserveCache: false);
        await _initializeNewControllers();
      }

      stopwatch.stop();
      if (mounted) {
        setState(() => _loadDuration = stopwatch.elapsedMilliseconds);
      }

      // Only prefetch next video
      if (widget.nextHlsUrl != null ||
          widget.nextPreviewUrl != null ||
          widget.nextVideoUrl != null) {
        _prefetchVideo(
          hlsUrl: widget.nextHlsUrl,
          previewUrl: widget.nextPreviewUrl,
          videoUrl: widget.nextVideoUrl,
        );
      }
    } catch (e) {
      debugPrint('Error in _setupVideoPlayer: $e');
      _cleanupControllers(preserveCache: false);
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  Future<void> _initializeNewControllers() async {
    // Try HLS first
    if (widget.hlsUrl != null) {
      try {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl!));
        await _controller!.initialize();
        _controller!.addListener(_errorListener);
        _setupChewieController();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
        return;
      } catch (e) {
        debugPrint('Error initializing HLS player: $e');
        _cleanupControllers();
      }
    }

    // Fall back to preview or original
    try {
      final urlToUse = widget.previewUrl ?? widget.videoUrl;
      _controller = VideoPlayerController.networkUrl(Uri.parse(urlToUse));
      await _controller!.initialize();
      _controller!.addListener(_errorListener);
      _setupChewieController();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing player: $e');
      _cleanupControllers();
      rethrow; // Propagate error to parent for handling
    }
  }

  void _setupChewieController() {
    if (_controller != null) {
      try {
        _chewieController = ChewieController(
          videoPlayerController: _controller!,
          autoPlay: true,
          looping: true,
          showControls: false,
          aspectRatio: _controller!.value.aspectRatio,
          showOptions: false,
          showControlsOnInitialize: false,
        );
      } catch (e) {
        debugPrint('Error setting up Chewie controller: $e');
        _cleanupControllers();
        rethrow;
      }
    }
  }

  Future<void> _prefetchVideo({
    String? hlsUrl,
    String? previewUrl,
    String? videoUrl,
  }) async {
    // Check cache size and clean if necessary
    if (FeedVideoPlayer._prefetchCache.length >=
        FeedVideoPlayer._maxCacheSize) {
      FeedVideoPlayer._cleanLeastRecentlyUsed();
    }

    // Try HLS first
    if (hlsUrl != null && !FeedVideoPlayer._prefetchCache.containsKey(hlsUrl)) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(hlsUrl));
        await controller.initialize();
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: true,
          showControls: false,
          aspectRatio: controller.value.aspectRatio,
          showOptions: false,
          showControlsOnInitialize: false,
        );
        FeedVideoPlayer._prefetchCache[hlsUrl] = (controller, chewieController);
        FeedVideoPlayer._markUrlAsUsed(hlsUrl);
        debugPrint('Successfully prefetched HLS: $hlsUrl');
        return;
      } catch (e) {
        debugPrint('Error prefetching HLS: $e');
      }
    }

    // Try preview URL next
    if (previewUrl != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(previewUrl)) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(previewUrl));
        await controller.initialize();
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: true,
          showControls: false,
          aspectRatio: controller.value.aspectRatio,
          showOptions: false,
          showControlsOnInitialize: false,
        );
        FeedVideoPlayer._prefetchCache[previewUrl] =
            (controller, chewieController);
        FeedVideoPlayer._markUrlAsUsed(previewUrl);
        debugPrint('Successfully prefetched preview: $previewUrl');
        return;
      } catch (e) {
        debugPrint('Error prefetching preview: $e');
      }
    }

    // Finally try original URL
    if (videoUrl != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(videoUrl)) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await controller.initialize();
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: true,
          showControls: false,
          aspectRatio: controller.value.aspectRatio,
          showOptions: false,
          showControlsOnInitialize: false,
        );
        FeedVideoPlayer._prefetchCache[videoUrl] =
            (controller, chewieController);
        FeedVideoPlayer._markUrlAsUsed(videoUrl);
        debugPrint('Successfully prefetched original: $videoUrl');
      } catch (e) {
        debugPrint('Error prefetching original: $e');
      }
    }
  }

  // Error listener to reinitialize the controller on playback error
  void _errorListener() {
    if (_controller?.value.hasError ?? false) {
      debugPrint(
          'Playback error detected: ${_controller!.value.errorDescription}');
      _controller!.removeListener(_errorListener);
      _cleanupControllers();
      if (mounted) {
        _initializeNewControllers();
      }
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing FeedVideoPlayer');
    _cleanupControllers();
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

    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
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
