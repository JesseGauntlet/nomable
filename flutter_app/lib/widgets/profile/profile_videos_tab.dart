import 'package:flutter/material.dart';
import '../../screens/video_preview_screen.dart';
import '../../services/user_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Widget that displays the user's videos in a grid layout in the profile screen
class ProfileVideosTab extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final bool isOwner; // if true, allows deletion (long-press selection)
  final VoidCallback? onVideosDeleted;

  const ProfileVideosTab({
    super.key,
    required this.videos,
    this.isOwner = false,
    this.onVideosDeleted,
  });

  @override
  State<ProfileVideosTab> createState() => _ProfileVideosTabState();
}

class _ProfileVideosTabState extends State<ProfileVideosTab> {
  final Set<String> _selectedVideos = {};
  final _userService = UserService();
  bool _isDeleting = false;

  Future<void> _deleteSelectedVideos() async {
    if (_selectedVideos.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Videos'),
          content: Text(
            'Are you sure you want to delete ${_selectedVideos.length} selected video${_selectedVideos.length > 1 ? 's' : ''}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      for (final postId in _selectedVideos) {
        final video = widget.videos.firstWhere((v) => v['id'] == postId);

        // Delete from Storage
        final storage = FirebaseStorage.instance;

        // Delete main video
        if (video['mediaUrl'] != null) {
          try {
            final videoRef = storage.refFromURL(video['mediaUrl']);
            await videoRef.delete();
          } catch (e) {
            print('Error deleting video file: $e');
          }
        }

        // Delete preview video
        if (video['previewUrl'] != null) {
          try {
            final previewRef = storage.refFromURL(video['previewUrl']);
            await previewRef.delete();
          } catch (e) {
            print('Error deleting preview file: $e');
          }
        }

        // Delete thumbnail
        if (video['thumbnailUrl'] != null) {
          try {
            final thumbnailRef = storage.refFromURL(video['thumbnailUrl']);
            await thumbnailRef.delete();
          } catch (e) {
            print('Error deleting thumbnail file: $e');
          }
        }

        // Delete HLS files if they exist
        if (video['hlsUrl'] != null) {
          try {
            final hlsUrl = video['hlsUrl'];
            final hlsRef = storage.refFromURL(hlsUrl);
            final hlsDir = hlsRef.parent;

            // List and delete all files in the HLS directory
            final items = await hlsDir?.listAll();
            if (items != null) {
              await Future.wait(items.items.map((ref) => ref.delete()));
            }
          } catch (e) {
            print('Error deleting HLS files: $e');
          }
        }

        // Delete from Firestore
        await _userService.deletePost(postId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Videos deleted successfully')),
        );
        setState(() {
          _selectedVideos.clear();
        });
        widget.onVideosDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting videos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            final String mediaUrl = video['mediaUrl'] ?? '';
            final String thumbnailUrl = video['thumbnailUrl'] ?? '';
            final String? previewUrl = video['previewUrl'];
            final String? hlsUrl = video['hlsUrl'];
            final int heartCount = video['heartCount'] ?? 0;
            final String userId = video['userId'] ?? '';
            final String postId = video['id'] ?? '';
            final bool isSelected = _selectedVideos.contains(postId);

            return GestureDetector(
              onTap: () {
                if (_selectedVideos.isNotEmpty && widget.isOwner) {
                  setState(() {
                    if (isSelected) {
                      _selectedVideos.remove(postId);
                    } else {
                      _selectedVideos.add(postId);
                    }
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPreviewScreen(
                        videoUrl: mediaUrl,
                        previewUrl: previewUrl,
                        hlsUrl: hlsUrl,
                        description: video['description'] ?? '',
                        foodTags: List<String>.from(video['foodTags'] ?? []),
                        heartCount: heartCount,
                        userId: userId,
                        postId: postId,
                      ),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (widget.isOwner) {
                  setState(() {
                    if (isSelected) {
                      _selectedVideos.remove(postId);
                    } else {
                      _selectedVideos.add(postId);
                    }
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumbnailUrl.isNotEmpty
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.video_library,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    // Selection overlay
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    // Heart count overlay
                    if (!isSelected)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                heartCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        // Delete button overlay
        if (_selectedVideos.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _deleteSelectedVideos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Delete ${_selectedVideos.length} selected',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
