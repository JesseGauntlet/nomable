import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class SwipeProgressAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final int currentSwipes;
  final double radius;

  const SwipeProgressAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.currentSwipes,
    this.radius = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress indicator
        SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CircularProgressIndicator(
            value: currentSwipes / UserService.maxDailySwipes,
            strokeWidth: 3,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              currentSwipes >= UserService.maxDailySwipes
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // Profile picture
        CircleAvatar(
          radius: radius - 4, // Slightly smaller to show progress indicator
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: radius * 0.64), // Proportional font size
                )
              : null,
        ),
      ],
    );
  }
}
