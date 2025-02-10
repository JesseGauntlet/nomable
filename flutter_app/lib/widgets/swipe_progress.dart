import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SwipeProgress extends StatelessWidget {
  final int currentSwipes;
  final int maxSwipes;

  const SwipeProgress({
    Key? key,
    required this.currentSwipes,
    this.maxSwipes = UserService.maxDailySwipes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$currentSwipes/$maxSwipes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value:
                    currentSwipes < maxSwipes ? currentSwipes / maxSwipes : 1.0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentSwipes >= maxSwipes ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
