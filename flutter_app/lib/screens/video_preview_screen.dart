import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../widgets/video_item.dart';

class VideoPreviewScreen extends StatelessWidget {
  final String videoUrl;
  final String? previewUrl;
  final String? hlsUrl;
  final String description;
  final List<String> foodTags;
  final int heartCount;
  final String userId;
  final String postId;

  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    this.previewUrl,
    this.hlsUrl,
    required this.description,
    required this.foodTags,
    required this.heartCount,
    required this.userId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final feedItem = FeedItem(
      id: postId,
      userId: userId,
      mediaUrl: videoUrl,
      previewUrl: previewUrl,
      hlsUrl: hlsUrl,
      mediaType: 'video',
      foodTags: foodTags,
      description: description,
      heartCount: heartCount,
      previewGenerated: previewUrl != null,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          VideoItem(
            item: feedItem,
            nextItem: null,
          ),

          // Back button overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
