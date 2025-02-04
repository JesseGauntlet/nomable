import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import 'video_action_buttons.dart';
import 'video_description.dart';
import 'feed_video_player.dart';

class VideoItem extends StatelessWidget {
  final FeedItem item;

  const VideoItem({
    super.key,
    required this.item,
  });

  bool _isValidVideoUrl(String? url) {
    if (url == null) return false;
    // Add Firebase Storage URL check
    return url.startsWith('http') &&
        (url.contains('firebasestorage.googleapis.com') ||
            url.contains('googleapis.com/v0/b/'));
  }

  Widget _buildVideoContent() {
    if (_isValidVideoUrl(item.mediaUrl)) {
      return FeedVideoPlayer(videoUrl: item.mediaUrl);
    }
    // Fallback for invalid URLs
    return const Center(child: Text('Invalid video URL'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video content (either player or placeholder)
        _buildVideoContent(),

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

        // Action buttons (like, bookmark, share)
        Positioned(
          right: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
          child: VideoActionButtons(
            heartCount: item.heartCount,
            bookmarkCount: item.bookmarkCount,
            onHeartPressed: () {
              // TODO: Implement heart action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Heart feature coming soon!')),
              );
            },
            onBookmarkPressed: () {
              // TODO: Implement bookmark action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark feature coming soon!')),
              );
            },
            onSharePressed: () {
              // TODO: Implement share action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ),

        // Video description and user info
        Positioned(
          left: 8,
          right: 72,
          bottom: MediaQuery.of(context).padding.bottom + 8,
          child: VideoDescription(
            username:
                item.userId, // TODO: Get actual username from user profile
            description: item.description,
            foodTags: item.foodTags,
          ),
        ),
      ],
    );
  }
}
