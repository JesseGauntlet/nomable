import 'package:flutter/material.dart';
import '../widgets/feed_video_player.dart';

class VideoPreviewScreen extends StatelessWidget {
  final String videoUrl;
  final String description;
  final List<String> foodTags;
  final int heartCount;

  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    required this.description,
    required this.foodTags,
    required this.heartCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Video player taking most of the screen
          Expanded(
            flex: 3,
            child: Center(
              child: FeedVideoPlayer(videoUrl: videoUrl),
            ),
          ),
          // Video details at the bottom
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Food tags
                  if (foodTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: foodTags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Heart count
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        heartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
