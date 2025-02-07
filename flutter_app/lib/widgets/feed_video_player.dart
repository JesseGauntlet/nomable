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
  static const int _maxCacheSize = 2;

  // Debug method to log cache state
  static void _logCacheState() {
    debugPrint('Cache state - URLs present: ${_prefetchCache.keys.toList()}');
  }

  // Aggressive cache cleanup: always clear the entire prefetch cache.
  static void _cleanCache() {
    debugPrint(
        'Aggressive cache cleanup: disposing all prefetched controllers');
    disposeCache();
  }

  // Method to dispose all cached controllers
  static void disposeCache() {
    debugPrint('Disposing all cached controllers');
    for (final controllers in _prefetchCache.values) {
      controllers.$2?.dispose(); // Dispose chewie controller if exists
      controllers.$1.dispose(); // Dispose video controller
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

  Future<void> _setupVideoPlayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

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
      final cached = FeedVideoPlayer._prefetchCache.remove(urlToUse)!;
      _controller = cached.$1;
      _chewieController = cached.$2;
      _wasPrefetched = true;
      if (!(_controller!.value.isPlaying)) {
        await _controller!.play();
      }
      setState(() => _isInitialized = true);
    } else {
      // Initialize new controllers if no cache hit
      await _initializeNewControllers();
    }

    stopwatch.stop();
    setState(() => _loadDuration = stopwatch.elapsedMilliseconds);

    // Prefetch next video
    if (widget.nextHlsUrl != null ||
        widget.nextPreviewUrl != null ||
        widget.nextVideoUrl != null) {
      _prefetchNextVideo();
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
        setState(() => _isInitialized = true);
        return;
      } catch (e) {
        debugPrint('Error initializing HLS player: $e');
        _controller?.dispose();
        _controller = null;
      }
    }

    // Fall back to preview or original
    try {
      final urlToUse = widget.previewUrl ?? widget.videoUrl;
      _controller = VideoPlayerController.networkUrl(Uri.parse(urlToUse));
      await _controller!.initialize();
      _controller!.addListener(_errorListener);
      _setupChewieController();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing player: $e');
      _controller?.dispose();
      _controller = null;
    }
  }

  void _setupChewieController() {
    if (_controller != null) {
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _controller!.value.aspectRatio,
        showOptions: false,
        showControlsOnInitialize: false,
      );
    }
  }

  Future<void> _prefetchNextVideo() async {
    // Clean up old cached controllers first
    FeedVideoPlayer._cleanCache();

    // Try to prefetch HLS first
    if (widget.nextHlsUrl != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(widget.nextHlsUrl)) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.nextHlsUrl!));
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
        FeedVideoPlayer._prefetchCache[widget.nextHlsUrl!] =
            (controller, chewieController);
        debugPrint('Successfully prefetched HLS: ${widget.nextHlsUrl}');
        return;
      } catch (e) {
        debugPrint('Error prefetching HLS: $e');
      }
    }

    // Fall back to preview URL
    if (widget.nextPreviewUrl != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(widget.nextPreviewUrl)) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.nextPreviewUrl!));
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
        FeedVideoPlayer._prefetchCache[widget.nextPreviewUrl!] =
            (controller, chewieController);
        debugPrint('Successfully prefetched preview: ${widget.nextPreviewUrl}');
        return;
      } catch (e) {
        debugPrint('Error prefetching preview: $e');
      }
    }

    // Finally try original URL
    if (widget.nextVideoUrl != null &&
        !FeedVideoPlayer._prefetchCache.containsKey(widget.nextVideoUrl)) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.nextVideoUrl!));
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
        FeedVideoPlayer._prefetchCache[widget.nextVideoUrl!] =
            (controller, chewieController);
        debugPrint('Successfully prefetched original: ${widget.nextVideoUrl}');
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
      _chewieController?.dispose();
      _controller?.dispose();
      _controller = null;
      _chewieController = null;
      if (mounted) {
        _initializeNewControllers();
      }
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
