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
    // Check for valid video URL that's not a mock/example URL
    return url.startsWith('http') &&
        !url.contains('example.com') &&
        !url.startsWith('sample_');
  }

  Widget _buildVideoContent() {
    // Check if we have a valid video URL
    if (_isValidVideoUrl(item.videoUrl)) {
      return FeedVideoPlayer(videoUrl: item.videoUrl!);
    }

    // Show placeholder for dummy data
    return Container(
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
            const SizedBox(height: 8),
            const Text(
              '(Demo Mode)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
