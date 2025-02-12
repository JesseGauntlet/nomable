import 'package:flutter/material.dart';
import 'dart:math' show max;
import '../../services/user_service.dart';

/// Widget that displays the user's food cravings data in the profile screen
class ProfileCravingsTab extends StatefulWidget {
  final String userId;

  const ProfileCravingsTab({super.key, required this.userId});

  @override
  State<ProfileCravingsTab> createState() => _ProfileCravingsTabState();
}

class _ProfileCravingsTabState extends State<ProfileCravingsTab> {
  final _userService = UserService();
  Map<String, int> _foodPreferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getUserById(widget.userId);
      if (mounted && user != null) {
        // Sort preferences by count in descending order and take top 8
        final sortedPreferences =
            Map.fromEntries(user.foodPreferences.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value))
              ..take(8));
        setState(() => _foodPreferences = sortedPreferences);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showResetConfirmation() async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser?.id != widget.userId) return;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Food Preferences'),
          content: const Text(
            'Would you like to archive your current preferences before resetting, or just reset them?\n\n'
            'Archive will store your current preferences history for tracking trends.\n\n'
            'This will also reset your daily swipe count.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('archive'),
              child: const Text(
                'ARCHIVE & RESET',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != null && confirmed != 'cancel' && mounted) {
      try {
        final user = await _userService.getUserById(widget.userId);
        if (user != null) {
          if (confirmed == 'archive') {
            // Create a preference history snapshot before resetting
            await _userService.archiveAndResetPreferences(
                user.id, user.foodPreferences);
          } else {
            // Just reset preferences
            await _userService.updateUser(user.id, {
              'foodPreferences': {},
            });
          }

          // Reset swipe count
          await _userService.resetSwipeCount();

          if (mounted) {
            setState(() => _foodPreferences = {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(confirmed == 'archive'
                    ? 'Preferences archived and reset successfully'
                    : 'Preferences reset successfully'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting preferences: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_foodPreferences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No cravings yet!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to track your food preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    // Get the maximum value for scaling
    final maxValue = _foodPreferences.values.reduce(max).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Food Cravings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset preferences',
                onPressed: _showResetConfirmation,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on ${_foodPreferences.length} food types',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _foodPreferences.length,
                      itemBuilder: (context, index) {
                        final entry = _foodPreferences.entries.elementAt(index);
                        final percentage = entry.value / maxValue;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 24,
                                          width:
                                              constraints.maxWidth * percentage,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Container(
                                width: 50,
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
