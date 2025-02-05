import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groups_screen.dart';

// FriendsScreen widget implements the friends list, pending friend requests,
// and a search functionality to add new friends.
// We are using Firestore subcollections 'friends' (for accepted friends) and 'friend_requests' (for pending requests).

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  FriendsScreenState createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Get current user from FirebaseAuth
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs: Friends and Requests
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method to send a friend request to a user
  Future<void> _sendFriendRequest(String targetUserId, String targetUserName,
      String? targetProfileUrl) async {
    if (currentUser == null) return;
    // We add a friend request document in the target user's 'friend_requests' subcollection.
    // Using currentUser.uid as the document id to avoid duplicate requests
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('friend_requests')
        .doc(currentUser!.uid)
        .set({
      'requestorId': currentUser!.uid,
      'requestorName': currentUser!.displayName ?? 'Anonymous',
      'requestorProfilePictureUrl': currentUser!.photoURL ?? '',
      'requestedAt': FieldValue.serverTimestamp(),
    });
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent')),
    );
  }

  // Accept a friend request
  Future<void> _acceptFriendRequest(String requestorId, String requestorName,
      String? requestorProfileUrl) async {
    if (currentUser == null) return;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Add the requestor to current user's 'friends' subcollection
    DocumentReference myFriendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .doc(requestorId);
    batch.set(myFriendRef, {
      'friendId': requestorId,
      'friendName': requestorName,
      'friendProfilePictureUrl': requestorProfileUrl ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    });

    // (Optional) Add current user to requestor's 'friends' subcollection for reciprocity
    DocumentReference theirFriendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(requestorId)
        .collection('friends')
        .doc(currentUser!.uid);
    batch.set(theirFriendRef, {
      'friendId': currentUser!.uid,
      'friendName': currentUser!.displayName ?? 'Anonymous',
      'friendProfilePictureUrl': currentUser!.photoURL ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Remove the friend request from current user's 'friend_requests' subcollection
    DocumentReference requestRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friend_requests')
        .doc(requestorId);
    batch.delete(requestRef);

    await batch.commit();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request accepted')),
    );
  }

  // Reject a friend request by simply deleting it from the subcollection
  Future<void> _rejectFriendRequest(String requestorId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friend_requests')
        .doc(requestorId)
        .delete();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request rejected')),
    );
  }

  // Method to build the UI for the list of friends
  Widget _buildFriendsList() {
    if (currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }
    // Listen to the 'friends' subcollection for the current user
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .orderBy('friendName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading friends'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friendsDocs = snapshot.data?.docs ?? [];
        if (friendsDocs.isEmpty) {
          return const Center(child: Text('No friends yet'));
        }
        return ListView.builder(
          itemCount: friendsDocs.length,
          itemBuilder: (context, index) {
            var friendData = friendsDocs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: friendData['friendProfilePictureUrl'] != ''
                    ? NetworkImage(friendData['friendProfilePictureUrl'])
                    : null,
                child: friendData['friendProfilePictureUrl'] == ''
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(friendData['friendName'] ?? 'No Name'),
              // More actions can be added here if needed
            );
          },
        );
      },
    );
  }

  // Build the UI for pending friend requests
  Widget _buildFriendRequests() {
    if (currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }
    // Listen to the 'friend_requests' subcollection for the current user
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friend_requests')
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading friend requests'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requestDocs = snapshot.data?.docs ?? [];
        if (requestDocs.isEmpty) {
          return const Center(child: Text('No pending friend requests'));
        }
        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            var requestData = requestDocs[index].data() as Map<String, dynamic>;
            String requestorId = requestData['requestorId'] ?? '';
            String requestorName = requestData['requestorName'] ?? 'No Name';
            String? requestorProfileUrl =
                requestData['requestorProfilePictureUrl'];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    requestorProfileUrl != null && requestorProfileUrl != ''
                        ? NetworkImage(requestorProfileUrl)
                        : null,
                child: requestorProfileUrl == null || requestorProfileUrl == ''
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(requestorName),
              subtitle: const Text('wants to be your friend'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Accept',
                    onPressed: () => _acceptFriendRequest(
                        requestorId, requestorName, requestorProfileUrl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Reject',
                    onPressed: () => _rejectFriendRequest(requestorId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show a dialog to search for new friends by name
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return AlertDialog(
          title: const Text('Search Users'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Enter name'),
            onChanged: (value) {
              searchQuery = value.trim();
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Close the dialog after search
                Navigator.of(context).pop();
                // Trigger search and show results in a new screen/dialog
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          SearchResultsScreen(searchQuery: searchQuery)),
                );
                _searchController.clear();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // Add Groups button in the app bar
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Food Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildFriendRequests(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add),
        tooltip: 'Search and add friends',
      ),
    );
  }
}

// This screen shows search results for users matching the search query.
// It queries the 'users' collection in Firestore.
class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  SearchResultsScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Query the 'users' collection for matching name
    Query userQuery = FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error searching users'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final results = snapshot.data?.docs ?? [];
          // Filter out the current user from results
          final filteredResults =
              results.where((doc) => doc.id != currentUser?.uid).toList();
          if (filteredResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No users found'),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with a different name',
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
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              var userData =
                  filteredResults[index].data() as Map<String, dynamic>;
              String userId = filteredResults[index].id;
              String name = userData['name'] ?? 'No Name';
              String? profileUrl = userData['profilePictureUrl'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileUrl != null && profileUrl != ''
                      ? NetworkImage(profileUrl)
                      : null,
                  child: (profileUrl == null || profileUrl == '')
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(name),
                trailing: ElevatedButton(
                  onPressed: () async {
                    // On pressing add, send a friend request
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('friend_requests')
                        .doc(currentUser!.uid)
                        .set({
                      'requestorId': currentUser!.uid,
                      'requestorName': currentUser!.displayName ?? 'Anonymous',
                      'requestorProfilePictureUrl': currentUser!.photoURL ?? '',
                      'requestedAt': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request sent')),
                    );
                  },
                  child: const Text('Add'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
