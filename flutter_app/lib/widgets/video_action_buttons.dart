import 'package:flutter/material.dart';

class VideoActionButtons extends StatelessWidget {
  final String userId;
  final int likes;
  final int comments;
  final double bottomPadding;

  const VideoActionButtons({
    super.key,
    required this.userId,
    required this.likes,
    required this.comments,
    this.bottomPadding = 100,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: bottomPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile picture
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    userId[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.favorite,
            label: _formatNumber(likes),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Like feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.comment,
            label: _formatNumber(comments),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comments feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.reply,
            label: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
