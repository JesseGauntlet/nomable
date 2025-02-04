import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../services/api_service.dart';
import '../widgets/feed_video_player.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final feedData = await ApiService.getFeed();
      if (!mounted) return;

      setState(() {
        _feedItems = feedData.map((item) => FeedItem.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
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
            onPressed: _loadFeed,
          ),
        ),
      );
    }
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon, color: color ?? Colors.white, size: 30),
            onPressed: onPressed,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(FeedItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player (full screen)
        Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              '🎥 Video Preview\n(Mock Data)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        // Overlay gradient for better text visibility
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side interaction buttons
        Positioned(
          right: 8,
          bottom: 80, // Adjusted to account for bottom navigation bar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Profile picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(item.userId[0].toUpperCase()),
                ),
              ),
              const SizedBox(height: 20),
              // Like button
              _buildInteractionButton(
                icon: Icons.favorite,
                label: item.likes.toString(),
                onPressed: () {
                  // TODO: Implement like functionality
                },
                color: Colors.white,
              ),
              // Comment button
              _buildInteractionButton(
                icon: Icons.comment,
                label: item.comments.toString(),
                onPressed: () {
                  // TODO: Implement comments functionality
                },
                color: Colors.white,
              ),
            ],
          ),
        ),

        // Bottom text overlay (username and description)
        Positioned(
          left: 16,
          bottom: 100, // Adjusted to account for bottom navigation bar
          right: 80, // Space for right side buttons
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${item.userId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load feed'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return const Center(
        child: Text('No videos available'),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        return _buildVideoItem(_feedItems[index]);
      },
    );
  }
}
