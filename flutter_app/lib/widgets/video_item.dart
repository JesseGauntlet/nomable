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
    if (_isValidVideoUrl(item.videoUrl)) {
      return FeedVideoPlayer(videoUrl: item.videoUrl!);
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

        // Action buttons (like, comment, share)
        VideoActionButtons(
          userId: item.userId,
          likes: item.likes,
          comments: item.comments,
        ),

        // Video description and user info
        VideoDescription(
          userId: item.userId,
          description: item.description,
        ),
      ],
    );
  }
}
