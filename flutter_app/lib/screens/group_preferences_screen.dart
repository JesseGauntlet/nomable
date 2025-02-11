import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class GroupPreferencesScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupPreferencesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  GroupPreferencesScreenState createState() => GroupPreferencesScreenState();
}

class GroupPreferencesScreenState extends State<GroupPreferencesScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();
  Map<String, double> groupPreferences = {};
  bool isLoading = true;
  Map<String, Map<String, dynamic>> memberData = {};

  @override
  void initState() {
    super.initState();
    _loadGroupPreferences();
    _loadMemberData();
  }

  Future<void> _loadGroupPreferences() async {
    if (currentUser == null) return;

    // Get all members of the group
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    final List<String> memberIds = List<String>.from(groupDoc['members'] ?? []);

    // Fetch food preferences for each member
    Map<String, double> aggregatedPreferences = {};

    for (String memberId in memberIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      final Map<String, dynamic>? memberPreferences =
          userDoc.data()?['foodPreferences'] as Map<String, dynamic>?;

      if (memberPreferences != null) {
        memberPreferences.forEach((food, score) {
          if (score is num) {
            aggregatedPreferences[food] =
                (aggregatedPreferences[food] ?? 0) + score.toDouble();
          }
        });
      }
    }

    // Sort preferences by score
    var sortedPreferences = Map.fromEntries(
      aggregatedPreferences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    // Take top 10 preferences
    var top10Preferences = Map.fromEntries(
      sortedPreferences.entries.take(10),
    );

    setState(() {
      groupPreferences = top10Preferences;
      isLoading = false;
    });
  }

  // Load member data including names and swipe counts
  Future<void> _loadMemberData() async {
    if (currentUser == null) return;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    final List<String> memberIds = List<String>.from(groupDoc['members'] ?? []);

    for (String memberId in memberIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      final userData = userDoc.data() ?? {};
      setState(() {
        memberData[memberId] = {
          'name': userData['name'] ?? 'Unknown User',
          'swipeCount': userData['swipeCount'] ?? 0,
        };
      });
    }
  }

  // Show confirmation dialog for initiating group vote
  Future<void> _showVoteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Group Vote'),
          content: const Text(
              'Are you sure you want to initiate a vote for the group? All members will be notified to start swiping.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initiateGroupVote();
              },
              child: const Text('Start Vote'),
            ),
          ],
        );
      },
    );
  }

  // Initiate the group vote and send notifications
  Future<void> _initiateGroupVote() async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Start Group Vote"),
            content: const Text(
                "This will reset everyone's swipe count and notify all group members to start swiping. Continue?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Create a new vote document
      final voteRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('votes')
          .doc();

      await voteRef.set({
        'initiatedBy': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Wait for the vote to be processed
      bool success = false;
      for (int i = 0; i < 10; i++) {
        // Try for up to 5 seconds
        await Future.delayed(const Duration(milliseconds: 500));

        final voteDoc = await voteRef.get();
        if (!voteDoc.exists) continue;

        final status = voteDoc.data()?['status'] as String?;
        if (status == 'completed') {
          success = true;
          break;
        } else if (status == 'error') {
          throw Exception(
              voteDoc.data()?['error'] ?? 'Failed to initiate group vote');
        }
      }

      if (!success) {
        throw Exception('Timeout waiting for vote processing');
      }

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group vote initiated! Members have been notified.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate group vote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} Preferences'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Froupin' time button
                  ElevatedButton.icon(
                    onPressed: _showVoteConfirmation,
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text("Froupin' time"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Member swipe progress
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Swipes Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...memberData.entries.map((entry) {
                            final swipeCount = entry.value['swipeCount'] as int;
                            final name = entry.value['name'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$swipeCount/10',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (swipeCount >= 10)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Existing preferences content
                  const Text(
                    'Group Food Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${groupPreferences.length} food types',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        itemCount: groupPreferences.length,
                        itemBuilder: (context, index) {
                          final entry =
                              groupPreferences.entries.elementAt(index);
                          final maxValue = groupPreferences.values
                              .reduce((a, b) => a > b ? a : b);
                          final percentage = entry.value / maxValue;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Food name with fixed width
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
                                // Bar container with flexible width
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 24,
                                            width: constraints.maxWidth *
                                                percentage,
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
                                // Value with fixed padding
                                Container(
                                  width: 50,
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    entry.value.toStringAsFixed(1),
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
