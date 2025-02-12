import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../trends_chart.dart';

/// Widget that displays the user's historical trend data in the profile screen
class ProfileTrendsTab extends StatefulWidget {
  const ProfileTrendsTab({super.key});

  @override
  State<ProfileTrendsTab> createState() => _ProfileTrendsTabState();
}

class _ProfileTrendsTabState extends State<ProfileTrendsTab> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<HistorySnapshot> _historySnapshots = [];

  @override
  void initState() {
    super.initState();
    _loadPreferenceHistory();
  }

  Future<void> _loadPreferenceHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get preference history sorted by date
      final snapshots = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferenceHistory')
          .orderBy('date', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _historySnapshots = snapshots.docs.map((doc) {
            final data = doc.data();
            return HistorySnapshot(
              date: (data['date'] as Timestamp).toDate(),
              preferences: Map<String, int>.from(data['preferences'] as Map),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preference history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historySnapshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No preference history yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Archive your preferences to see trends',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Food Preference Trends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TrendsChart(
            snapshots: _historySnapshots,
            topFoodsCount: 5,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Based on ${_historySnapshots.length} archived snapshots',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
