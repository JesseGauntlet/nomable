import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_item.dart';
import '../widgets/video_item.dart';

// Feed screen of videos / image[] posts (todo)
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<FeedItem> _feedItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMoreItems = true;
  final PageController _pageController = PageController();
  DocumentSnapshot? _lastDocument; // Track the last document for pagination

  // Number of items to fetch per page
  static const int _itemsPerPage = 10;

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
    if (!mounted || _isLoading || (!refresh && !_hasMoreItems)) return;

    setState(() {
      if (refresh) {
        _feedItems.clear();
        _lastDocument = null;
        _hasMoreItems = true;
      }
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(_itemsPerPage);

      // If this is not a refresh and we have a last document, start after it
      if (!refresh && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      if (!mounted) return;

      if (docs.isNotEmpty) {
        _lastDocument = docs.last;
        setState(() {
          _feedItems.addAll(docs.map((doc) => FeedItem.fromFirestore(doc)));
          _hasMoreItems = docs.length >= _itemsPerPage;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _hasMoreItems = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('FeedScreen: Error loading feed: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
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
    if (_isLoading && _feedItems.isEmpty) {
      return _buildLoadingState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        // If we're nearing the end of our loaded items, fetch more
        if (index >= _feedItems.length - 2) {
          _loadFeed();
        }
      },
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        final currentItem = _feedItems[index];
        final nextItem =
            index < _feedItems.length - 1 ? _feedItems[index + 1] : null;

        return VideoItem(
          item: currentItem,
          nextItem: nextItem,
        );
      },
    );
  }
}
