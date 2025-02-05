import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class GroupPreferencesScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupPreferencesScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupPreferencesScreenState createState() => _GroupPreferencesScreenState();
}

class _GroupPreferencesScreenState extends State<GroupPreferencesScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, double> groupPreferences = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupPreferences();
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
          : groupPreferences.isEmpty
              ? const Center(child: Text('No preferences data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
