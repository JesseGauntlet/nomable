import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feed_item.dart';
import '../services/api_service.dart';
import '../widgets/video_item.dart';

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

  Widget _buildLoadingState() {
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

  Widget _buildErrorState() {
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

  Widget _buildEmptyState() {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_hasError && _feedItems.isEmpty) return _buildErrorState();
    if (_feedItems.isEmpty) return _buildEmptyState();

    return Scaffold(
      body: Stack(
        children: [
          // Full screen PageView
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
              return VideoItem(item: _feedItems[index]);
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
