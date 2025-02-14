import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_members_screen.dart';
import 'group_preferences_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Method to create a new group
  void _createNewGroup() {
    showDialog(
      context: context,
      builder: (context) {
        String groupName = '';
        return AlertDialog(
          title: const Text('Create New Group'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter group name',
              labelText: 'Group Name',
            ),
            onChanged: (value) => groupName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (groupName.trim().isNotEmpty && currentUser != null) {
                  // Create the group in Firestore
                  DocumentReference groupRef = await FirebaseFirestore.instance
                      .collection('groups')
                      .add({
                    'name': groupName.trim(),
                    'creatorId': currentUser!.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                    'members': [currentUser!.uid],
                    'currentConsensusFood': '',
                    'vetoes': {},
                  });

                  // Add creator as first member
                  await groupRef
                      .collection('members')
                      .doc(currentUser!.uid)
                      .set({
                    'userId': currentUser!.uid,
                    'joinedAt': FieldValue.serverTimestamp(),
                    'name': currentUser!.displayName ?? 'Anonymous',
                    'photoUrl': currentUser!.photoURL,
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Please log in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Groups'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data?.docs ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create a group to decide what to eat together!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index].data() as Map<String, dynamic>;
              final groupId = groups[index].id;
              final isCreator = group['creatorId'] == currentUser!.uid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                      '${group['name'] ?? 'Unnamed Group'} (${(group['members'] as List<dynamic>).length})'),
                  subtitle: Text(
                    (group['consensusReached'] == true &&
                            group['topChoice'] != null &&
                            (group['topChoice'] as String).isNotEmpty)
                        ? 'Today\'s Choice: ${group["topChoice"]}'
                        : (group['currentConsensusFood']?.isNotEmpty ?? false)
                            ? 'Current craving: ${group["currentConsensusFood"]}'
                            : '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: isCreator
                      ? IconButton(
                          icon: const Icon(Icons.people_alt),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupMembersScreen(
                                  groupId: groupId,
                                  groupName: group['name'] ?? 'Unnamed Group',
                                  isCreator: isCreator,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Manage members',
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupPreferencesScreen(
                          groupId: groupId,
                          groupName: group['name'] ?? 'Unnamed Group',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroup,
        child: const Icon(Icons.group_add),
        tooltip: 'Create new group',
      ),
    );
  }
}
