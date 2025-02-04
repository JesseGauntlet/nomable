import 'package:flutter/material.dart';

class VideoActionButtons extends StatelessWidget {
  final int heartCount;
  final int bookmarkCount;
  final VoidCallback? onHeartPressed;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onSharePressed;
  final double bottomPadding;

  const VideoActionButtons({
    super.key,
    required this.heartCount,
    required this.bookmarkCount,
    this.onHeartPressed,
    this.onBookmarkPressed,
    this.onSharePressed,
    this.bottomPadding = 100,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    double size = 28,
  }) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: size),
            color: color ?? Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.favorite,
            label: heartCount.toString(),
            onPressed: onHeartPressed,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.bookmark,
            label: bookmarkCount.toString(),
            onPressed: onBookmarkPressed,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: onSharePressed,
          ),
        ],
      ),
    );
  }
}
