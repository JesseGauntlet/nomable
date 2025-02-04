import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feed_item.dart';
import '../services/api_service.dart';
import '../widgets/feed_video_player.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<FeedItem> _feedItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  final PageController _pageController = PageController();

  // Number of items to fetch per page
  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for better visibility
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadFeed(refresh: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    print('FeedScreen: _loadFeed called with refresh=$refresh');
    if (!mounted) return;

    // Don't load if we're already loading or if we've reached the end
    if (_isLoading || _isLoadingMore || (!_hasMoreItems && !refresh)) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _feedItems.clear();
        _currentPage = 0;
        _hasMoreItems = true;
      } else {
        _isLoadingMore = true;
      }
      _hasError = false;
    });

    try {
      final feedData = await ApiService.getFeed(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (!mounted) return;

      setState(() {
        if (feedData.isEmpty) {
          _hasMoreItems = false;
        } else {
          final newItems =
              feedData.map((item) => FeedItem.fromJson(item)).toList();
          _feedItems.addAll(newItems);
          _currentPage++;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('FeedScreen: Error loading feed: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading feed: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadFeed(refresh: true),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    double size = 28,
  }) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: size),
            color: color ?? Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoItem(FeedItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white70,
                  size: 84,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video ${item.id}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Gradient overlays for better text visibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 8,
          bottom: 100, // Adjusted for bottom navigation bar
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile picture
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        item.userId[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Like button
              _buildActionButton(
                icon: Icons.favorite,
                label: _formatNumber(item.likes),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Like feature coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              // Comment button
              _buildActionButton(
                icon: Icons.comment,
                label: _formatNumber(item.comments),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comments feature coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              // Share button
              _buildActionButton(
                icon: Icons.reply,
                label: 'Share',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                color: Colors.white,
              ),
            ],
          ),
        ),

        // Bottom text content
        Positioned(
          left: 16,
          right: 88, // Space for right side buttons
          bottom: 100, // Adjusted for bottom navigation bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '@${item.userId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Music info row
              Row(
                children: [
                  const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Original Sound - ${item.userId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading feed...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError && _feedItems.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load feed',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFeed(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No videos available',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full screen PageView with explicit scroll physics
          PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: _feedItems.length + (_hasMoreItems ? 1 : 0),
            onPageChanged: (index) {
              print("PageView: Page changed to index $index");
              if (index >= _feedItems.length - 2) {
                _loadFeed();
              }
            },
            itemBuilder: (context, index) {
              if (index == _feedItems.length) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return _buildVideoItem(_feedItems[index]);
            },
          ),

          // Top gradient overlay
          Container(
            height: MediaQuery.of(context).padding.top + 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
