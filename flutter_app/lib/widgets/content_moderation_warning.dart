import 'package:flutter/material.dart';

class ContentModerationWarning extends StatelessWidget {
  final bool? isFoodRelated;
  final bool? isNsfw;
  final String? moderationReason;
  final VoidCallback onContinue;

  const ContentModerationWarning({
    super.key,
    required this.isFoodRelated,
    required this.isNsfw,
    required this.moderationReason,
    required this.onContinue,
  });

  String _getWarningMessage() {
    if (isNsfw == true) {
      return 'This content has been flagged as inappropriate.';
    }
    if (isFoodRelated == false) {
      return 'This content does not appear to be food-related.';
    }
    return moderationReason ??
        'This content has been flagged by our moderation system.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Content Warning',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                _getWarningMessage(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Show Content Anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
