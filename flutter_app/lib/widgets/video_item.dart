import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../services/user_cache_service.dart';
import '../services/user_service.dart';
import 'video_action_buttons.dart';
import 'video_description.dart';
import 'feed_video_player.dart';

class VideoItem extends StatefulWidget {
  final FeedItem item;

  const VideoItem({
    super.key,
    required this.item,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  final _userCache = UserCacheService();
  final _userService = UserService();
  String? _username;
  String? _userPhotoUrl;
  bool _isLoadingUsername = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final (username, photoUrl) =
        await _userCache.getUserInfo(widget.item.userId);
    if (mounted) {
      setState(() {
        _username = username;
        _userPhotoUrl = photoUrl;
        _isLoadingUsername = false;
      });
    }
  }

  bool _isValidVideoUrl(String? url) {
    if (url == null) return false;
    // Add Firebase Storage URL check
    return url.startsWith('http') &&
        (url.contains('firebasestorage.googleapis.com') ||
            url.contains('googleapis.com/v0/b/'));
  }

  Widget _buildVideoContent() {
    if (_isValidVideoUrl(widget.item.mediaUrl)) {
      return FeedVideoPlayer(videoUrl: widget.item.mediaUrl);
    }
    // Fallback for invalid URLs
    return const Center(child: Text('Invalid video URL'));
  }

  Future<void> _handleHeartPress() async {
    try {
      await _userService.heartPost(
        postId: widget.item.id,
        foodTags: widget.item.foodTags,
      );

      // Update the UI to show the heart count increased
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your food preferences!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to heart post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video content (either player or placeholder)
          Positioned.fill(
            child: _buildVideoContent(),
          ),

          // Gradient overlays for better text visibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.3, 0.5],
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Profile picture above action buttons
          Positioned(
            right: 8,
            bottom: bottomPadding +
                275, // Increased from 160 to 220 to position above heart button
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Navigate to user profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('View profile coming soon!')),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _userPhotoUrl != null
                          ? NetworkImage(_userPhotoUrl!)
                          : _username != null
                              ? NetworkImage(
                                  'https://ui-avatars.com/api/?name=$_username&background=random')
                              : null,
                      child: _isLoadingUsername
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : (_userPhotoUrl == null && _username == null)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Action buttons (like, bookmark, share)
          Positioned(
            right: 8,
            bottom: bottomPadding + 20,
            child: VideoActionButtons(
              heartCount: widget.item.heartCount,
              bookmarkCount: widget.item.bookmarkCount,
              onHeartPressed: _handleHeartPress,
              onBookmarkPressed: () {
                // TODO: Implement bookmark action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Bookmark feature coming soon!')),
                );
              },
              onSharePressed: () {
                // TODO: Implement share action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              bottomPadding: 0,
            ),
          ),

          // Video description and user info
          Positioned(
            left: 8,
            right: 72,
            bottom: bottomPadding + 20,
            child: VideoDescription(
              username: _username ?? widget.item.userId,
              isLoadingUsername: _isLoadingUsername,
              description: widget.item.description,
              foodTags: widget.item.foodTags,
              bottomPadding: 0,
            ),
          ),
        ],
      ),
    );
  }
}
