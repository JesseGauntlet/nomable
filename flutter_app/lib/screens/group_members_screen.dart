import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isCreator;

  const GroupMembersScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.isCreator,
  }) : super(key: key);

  @override
  _GroupMembersScreenState createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? groupDoc;

  @override
  void initState() {
    super.initState();
    _loadGroupDoc();
  }

  Future<void> _loadGroupDoc() async {
    groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
  }

  // Show dialog to add members from friends list
  void _showAddMembersDialog() async {
    if (currentUser == null) return;

    // Get current group members
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    List<String> currentMembers = List<String>.from(groupDoc['members'] ?? []);

    // Show dialog with friends list
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('friends')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final friends = snapshot.data?.docs ?? [];
              if (friends.isEmpty) {
                return const Text('No friends to add');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index].data() as Map<String, dynamic>;
                  final friendId = friend['friendId'] as String;
                  final isAlreadyMember = currentMembers.contains(friendId);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          friend['friendProfilePictureUrl'] != null &&
                                  friend['friendProfilePictureUrl'] != ''
                              ? NetworkImage(friend['friendProfilePictureUrl'])
                              : null,
                      child: friend['friendProfilePictureUrl'] == null ||
                              friend['friendProfilePictureUrl'] == ''
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(friend['friendName'] ?? 'No Name'),
                    trailing: isAlreadyMember
                        ? const Text('Member',
                            style: TextStyle(color: Colors.grey))
                        : ElevatedButton(
                            onPressed: () async {
                              // Add member to group
                              await FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(widget.groupId)
                                  .update({
                                'members': FieldValue.arrayUnion([friendId])
                              });

                              // Add member details to members subcollection
                              await FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(widget.groupId)
                                  .collection('members')
                                  .doc(friendId)
                                  .set({
                                'userId': friendId,
                                'name': friend['friendName'],
                                'photoUrl': friend['friendProfilePictureUrl'],
                                'joinedAt': FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${friend['friendName']} added to group'),
                                ),
                              );
                            },
                            child: const Text('Add'),
                          ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Remove a member from the group
  Future<void> _removeMember(String memberId, String memberName) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
                'Are you sure you want to remove $memberName from the group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Remove member from group
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({
      'members': FieldValue.arrayRemove([memberId])
    });

    // Remove member from members subcollection
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(memberId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$memberName removed from group')),
    );
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
        title: Text('${widget.groupName} Members'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (widget.isCreator)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMembersDialog,
              tooltip: 'Add members',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('members')
            .orderBy('joinedAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data?.docs ?? [];

          if (members.isEmpty) {
            return const Center(child: Text('No members'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index].data() as Map<String, dynamic>;
              final memberId = members[index].id;
              final isCreator =
                  groupDoc != null && memberId == groupDoc!['creatorId'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      member['photoUrl'] != null && member['photoUrl'] != ''
                          ? NetworkImage(member['photoUrl'])
                          : null,
                  child: member['photoUrl'] == null || member['photoUrl'] == ''
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(member['name'] ?? 'No Name'),
                subtitle: isCreator ? const Text('Creator') : null,
                trailing: widget.isCreator && !isCreator
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => _removeMember(
                          memberId,
                          member['name'] ?? 'No Name',
                        ),
                        tooltip: 'Remove member',
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
