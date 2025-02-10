import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SwipeProgress extends StatelessWidget {
  final int currentSwipes;
  final int maxSwipes;

  const SwipeProgress({
    super.key,
    required this.currentSwipes,
    this.maxSwipes = UserService.maxDailySwipes,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentSwipes / maxSwipes;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1 ? Colors.green : theme.colorScheme.primary,
                  ),
                  strokeWidth: 3,
                ),
              ),
              Text(
                '$currentSwipes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            'Daily Swipes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
